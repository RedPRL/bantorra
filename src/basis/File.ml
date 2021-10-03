open StdLabels
module U = UnixLabels
module E = Errors
open ResultMonad.Syntax

type filepath = string

let (/) p1 p2 =
  if Filename.is_relative p2 then Filename.concat p1 p2 else p2

let join = List.fold_left ~f:(/) ~init:Filename.current_dir_name

(** Write a string to a file. *)
let writefile p s =
  let src = "File.writefile" in
  try
    let ch = open_out_bin p in
    Fun.protect ~finally:(fun () -> close_out_noerr ch) @@
    fun () ->
    output_string ch s;
    close_out ch;
    ret ()
  with Sys_error msg -> E.error_system_msg ~src msg

(** Read the entire file as a string. *)
let readfile p =
  let src = "File.readfile" in
  try
    let ch = open_in_bin p in
    Fun.protect ~finally:(fun () -> close_in_noerr ch) @@
    fun () ->
    let s = really_input_string ch (in_channel_length ch) in
    close_in ch;
    ret s
  with Sys_error msg -> E.error_system_msg ~src msg

let getcwd = Sys.getcwd

(** OCaml implementation of [mkdir -p] *)
let rec ensure_dir path =
  let src = "File.ensure_dir" in
  match Sys.is_directory path with
  | false ->
    E.error_system_msgf ~src
      "%s exists but is not a directory" path
  | true -> ret ()
  | exception Sys_error _ ->
    let parent = Filename.dirname path in
    let* () = ensure_dir parent in
    let rec loop () =
      try ret @@ U.mkdir ~perm:0o777 path with
      | U.Unix_error (U.EINTR, _,  _) -> loop () (* try again *)
      | U.Unix_error (e, _,  _) ->
        E.error_system_msg ~src @@ U.error_message e
    in
    loop ()

let normalize_dir dir =
  let src = "File.normalize_dir" in
  let rec loop () =
    try ret @@ U.realpath dir with
    | U.Unix_error (U.EINTR, _,  _) -> loop () (* try again *)
    | U.Unix_error (e, _,  _) ->
      E.error_system_msg ~src @@ U.error_message e
  in
  loop ()

let parent_of_normalized_dir dir =
  let p = Filename.dirname dir in
  if p = dir then None else Some p

let file_exists p =
  try U.(stat p).st_kind = S_REG with _ -> false

let locate_anchor ~anchor start_dir =
  let src = "File.locate_anchor" in
  let rec find_root cwd unitpath_acc =
    if file_exists (cwd/anchor) then
      ret (cwd, unitpath_acc)
    else
      match parent_of_normalized_dir cwd with
      | None ->
        E.error_anchor_not_found_msg ~src
          "No anchor found all the way up to the root"
      | Some parent ->
        find_root parent @@ Filename.basename cwd :: unitpath_acc
  in
  match normalize_dir start_dir with
  | Ok cwd ->
    find_root cwd []
  | Error (`SystemError msg) ->
    E.append_error_anchor_not_found_msgf ~earlier:msg ~src
      "%s is invalid" start_dir

let hijacking_anchors_exist ~anchor ~root =
  function
  | [] -> false
  | first :: parts ->
    let rec loop cwd parts =
      if file_exists (cwd/anchor) then
        true
      else
        match parts with
        | [] -> false
        | part :: parts ->
          loop (cwd/part) parts
    in
    match normalize_dir (root/first) with
    | Error (`SystemError _) -> false
    | Ok cwd -> loop cwd parts

(** The scheme refers to how various directories should be determined.

    It does not correspond to the actual OS that is running. For example, the
    [Linux] scheme covers all BSD-like systems and Cygwin on Windows. *)
type scheme = MacOS | Linux | Windows

let getenv_opt = Sys.getenv_opt

let uname_s =
  lazy begin
    Result.to_option @@
    Exec.with_system_in ~prog:"uname" ~args:["-s"] @@ fun ic ->
    String.trim @@ input_line ic
  end

let guess_scheme =
  lazy begin
    match Sys.os_type with
    | "Unix" ->
      begin
        match Lazy.force uname_s with
        | Some "Darwin" -> MacOS
        | _ -> Linux
      end
    | "Cygwin" -> Linux
    | "Win32" -> Windows
    | _ -> Linux
  end

let get_home () =
  match Lazy.force guess_scheme with
  | Windows ->
    begin
      match getenv_opt "USERPROFILE" with
      | Some userprofile -> Some userprofile
      | None ->
        match getenv_opt "HOMEPATH" with
        | None -> None
        | Some homepath ->
          let drive = Option.value ~default:"" @@ Sys.getenv_opt "HOMEDRIVE" in
          Some (drive/homepath)
    end
  | Linux | MacOS ->
    match getenv_opt "HOME" with
    | Some home -> Some home
    | None ->
      let rec loop () =
        try
          Some Unix.(getpwuid @@ getuid ()).pw_dir
        with
        | Not_found (* getpwuid *) -> None
        | Unix.Unix_error (Unix.EINTR, _, _) -> loop ()
        | Unix.Unix_error _ -> None
      in
      loop ()

let expand_home =
  (* ["~/"] in the most portable way *)
  let home_prefix = "~" ^ Filename.dir_sep in
  fun p ->
    match get_home () with
    | None -> p
    | Some home ->
      if p = "~" then
        home
      else if String.(length p >= length home_prefix) &&
              String.(sub ~pos:0 ~len:(length home_prefix) p = home_prefix)
      then
        home / String.sub ~pos:1 ~len:(String.length p - 1) p
      else
        p

(* XXX I did not test the following code on different platforms. *)
let get_xdg_config_home ?(macos_as_linux=false) ~app_name =
  let src = "File.get_xdg_config_home" in
  match getenv_opt "XDG_CONFIG_HOME" with
  | Some dir -> ret @@ dir/app_name
  | None ->
    match Lazy.force guess_scheme, macos_as_linux with
    | Linux, _ | MacOS, true ->
      begin
        match get_home () with
        | None ->
          E.error_system_msg ~src
            "Both XDG_CONFIG_HOME and HOME are not set"
        | Some home ->
          ret @@ home/".config"/app_name
      end
    | MacOS, false ->
      begin
        match get_home () with
        | None ->
          E.error_system_msg ~src
            "Both XDG_CONFIG_HOME and HOME are not set"
        | Some home ->
          ret @@ home/"Library"/"Application Support"/app_name
      end
    | Windows, _ ->
      begin
        match getenv_opt "APPDATA" with
        | None ->
          E.error_system_msg ~src
            "Both XDG_CONFIG_HOME and APPDATA are not set"
        | Some app_data ->
          ret @@ app_data/app_name/"config"
      end

(* XXX I did not test the following code on different platforms. *)
let get_xdg_cache_home ?(macos_as_linux=false) ~app_name =
  let src = "File.get_xdg_cache_home" in
  match Sys.getenv_opt "XDG_CACHE_HOME" with
  | Some dir -> ret @@ dir/app_name
  | None ->
    match Lazy.force guess_scheme, macos_as_linux with
    | Linux, _ | MacOS, true ->
      begin
        match get_home () with
        | None ->
          E.error_system_msg ~src
            "Both XDG_CACHE_HOME and HOME are not set"
        | Some home ->
          ret @@ home/".cache"/app_name
      end
    | MacOS, false ->
      begin
        match get_home () with
        | None ->
          E.error_system_msg ~src
            "Both XDG_CACHE_HOME and HOME are not set"
        | Some home ->
          ret @@ home/"Library"/"Caches"/app_name
      end
    | Windows, _ ->
      begin
        match getenv_opt "LOCALAPPDATA" with
        | None ->
          E.error_system_msg ~src
            "Both XDG_CACHE_HOME and LOCALAPPDATA are not set"
        | Some local_app_data ->
          ret @@ local_app_data/app_name/"cache"
      end

let input_absolute_dir ?(starting_dir=Filename.current_dir_name) path =
  normalize_dir (starting_dir / expand_home path)

let input_relative_dir path =
  if Filename.is_relative path then path
  else Filename.(concat current_dir_name path)
