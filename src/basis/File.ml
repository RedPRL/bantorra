module U = Unix
module E = Error
module F = FilePath

(* invariant: absolute path *)
type path = F.t

let (/) = F.add_unit_seg

let wrap_bos =
  function
  | Ok r -> r
  | Error (`Msg msg) -> E.fatalf `System "%s" msg

(** Write a string to a file. *)
let write p s =
  E.tracef "File.write(%a)" F.pp p @@ fun () ->
  wrap_bos @@ Bos.OS.File.write (F.to_fpath p) s

(** Read the entire file as a string. *)
let read p =
  E.tracef "File.read(%a)" F.pp p @@ fun () ->
  wrap_bos @@ Bos.OS.File.read (F.to_fpath p)

let get_cwd () = F.of_fpath @@ wrap_bos @@ Bos.OS.Dir.current ()

let ensure_dir p =
  E.tracef "File.ensure_dir(%a)" F.pp p @@ fun () ->
  ignore @@ wrap_bos @@ Bos.OS.Dir.create (F.to_fpath p)

let file_exists p =
  wrap_bos @@ Bos.OS.File.exists (F.to_fpath p)

let locate_anchor ~anchor start_dir =
  E.tracef "File.locate_anchor(%s,%a)" anchor F.pp start_dir @@ fun () ->
  let rec go cwd path_acc =
    if file_exists (cwd/anchor) then
      cwd, UnitPath.of_list path_acc
    else
    if F.is_root cwd
    then E.fatalf `AnchorNotFound "No anchor found all the way up to the root"
    else go (F.parent cwd) @@ F.basename cwd :: path_acc
  in
  go start_dir []

let locate_hijacking_anchor ~anchor ~root path =
  E.tracef "File.hijacking_anchors_exist(%s,%a)" anchor F.pp root @@ fun () ->
  match UnitPath.to_list path with
  | [] -> None
  | first_seg :: segs ->
    let rec loop cwd parts =
      if file_exists (cwd/anchor) then
        Some cwd
      else
        match parts with
        | [] -> None
        | seg :: segs ->
          loop (cwd/seg) segs
    in
    loop (root/first_seg) segs

(** The scheme refers to how various directories should be determined.

    It does not correspond to the actual OS that is running. For example, the
    [Linux] scheme covers all BSD-like systems and Cygwin on Windows. *)
type scheme = MacOS | Linux | Windows

let uname_s =
  lazy begin
    Result.to_option @@
    Bos.OS.Cmd.(in_null |> run_io Bos.Cmd.(v "uname" % "-s") |> to_string ~trim:true)
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
  F.of_fpath @@ wrap_bos @@ Bos.OS.Dir.user ()

let read_env_path var =
  Result.map (F.of_fpath ~relative_to:(get_cwd ())) @@ Bos.OS.Env.path var

(* XXX I did not test the following code on different platforms. *)
let get_xdg_config_home ~app_name =
  E.tracef "File.get_xdg_config_home" @@ fun () ->
  match read_env_path "XDG_CONFIG_HOME" with
  | Ok dir -> dir/app_name
  | Error _ ->
    match Lazy.force guess_scheme with
    | Linux ->
      let home =
        E.try_with get_home
          ~fatal:(fun _ -> E.fatalf `System "Both XDG_CONFIG_HOME and HOME are not set")
      in
      home/".config"/app_name
    | MacOS ->
      let home =
        E.try_with get_home
          ~fatal:(fun _ -> E.fatalf `System "Both XDG_CONFIG_HOME and HOME are not set")
      in
      home/"Library"/"Application Support"/app_name
    | Windows ->
      begin
        match read_env_path "APPDATA" with
        | Ok app_data ->
          app_data/app_name/"config"
        | Error _ ->
          E.fatalf `System "Both XDG_CONFIG_HOME and APPDATA are not set"
      end

(* XXX I did not test the following code on different platforms. *)
let get_xdg_cache_home ~app_name =
  E.tracef "File.get_xdg_cache_home" @@ fun () ->
  match read_env_path "XDG_CACHE_HOME" with
  | Ok dir -> dir/app_name
  | Error _ ->
    match Lazy.force guess_scheme with
    | Linux ->
      let home =
        E.try_with get_home
          ~fatal:(fun _ -> E.fatalf `System "Both XDG_CACHE_HOME and HOME are not set")
      in
      home/".cache"/app_name
    | MacOS ->
      let home =
        E.try_with get_home
          ~fatal:(fun _ -> E.fatalf `System "Both XDG_CACHE_HOME and HOME are not set")
      in
      home/"Library"/"Caches"/app_name
    | Windows ->
      begin
        match read_env_path "LOCALAPPDATA" with
        | Error _ ->
          E.fatalf `System "Both XDG_CACHE_HOME and LOCALAPPDATA are not set"
        | Ok local_app_data ->
          local_app_data/app_name/"cache"
      end
