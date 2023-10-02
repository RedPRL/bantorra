module U = Unix
module F = FilePath

(* invariant: absolute path *)
type path = F.t

let (/) = F.add_unit_seg

let wrap_bos =
  function
  | Ok r -> r
  | Error (`Msg msg) -> Logger.fatal `System msg

let get_cwd () = F.of_fpath @@ wrap_bos @@ Bos.OS.Dir.current ()

(** Read the entire file as a string. *)
let read p =
  Logger.tracef "When reading the file `%a'" (F.pp ~relative_to:(get_cwd())) p @@ fun () ->
  wrap_bos @@ Bos.OS.File.read (F.to_fpath p)

(** Write a string to a file. *)
let write p s =
  Logger.tracef "When writing the file `%a'" (F.pp ~relative_to:(get_cwd())) p @@ fun () ->
  wrap_bos @@ Bos.OS.File.write (F.to_fpath p) s

let ensure_dir p =
  Logger.tracef "When calling `ensure_dir' on `%a'" (F.pp ~relative_to:(get_cwd())) p @@ fun () ->
  ignore @@ wrap_bos @@ Bos.OS.Dir.create (F.to_fpath p)

let file_exists p =
  wrap_bos @@ Bos.OS.File.exists (F.to_fpath p)

let locate_anchor ~anchor start_dir =
  Logger.tracef "When locating the anchor `%s' from `%a'"
    anchor (F.pp ~relative_to:(get_cwd())) start_dir @@ fun () ->
  let rec go cwd path_acc =
    if file_exists (cwd/anchor) then
      cwd, UnitPath.of_list path_acc
    else
    if F.is_root cwd
    then Logger.fatal `AnchorNotFound "No anchor found all the way up to the root"
    else go (F.parent cwd) @@ F.basename cwd :: path_acc
  in
  go (F.to_dir_path start_dir) []

let locate_hijacking_anchor ~anchor ~root path =
  Logger.tracef "When checking whether there's any hijacking anchor `%s'@ between `%a' and `%a'"
    anchor (F.pp ~relative_to:(get_cwd())) root UnitPath.pp path @@ fun () ->
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
  Logger.trace "When calculating the XDG_CONFIG_HOME" @@ fun () ->
  match read_env_path "XDG_CONFIG_HOME" with
  | Ok dir -> dir/app_name
  | Error _ ->
    match Lazy.force guess_scheme with
    | Linux ->
      let home =
        Logger.try_with get_home
          ~fatal:(fun _ -> Logger.fatal `System "Both XDG_CONFIG_HOME and HOME are not set")
      in
      home/".config"/app_name
    | MacOS ->
      let home =
        Logger.try_with get_home
          ~fatal:(fun _ -> Logger.fatal `System "Both XDG_CONFIG_HOME and HOME are not set")
      in
      home/"Library"/"Application Support"/app_name
    | Windows ->
      begin
        match read_env_path "APPDATA" with
        | Ok app_data ->
          app_data/app_name/"config"
        | Error _ ->
          Logger.fatal `System "Both XDG_CONFIG_HOME and APPDATA are not set"
      end

(* XXX I did not test the following code on different platforms. *)
let get_xdg_cache_home ~app_name =
  Logger.tracef "When calculating XDG_CACHE_HOME" @@ fun () ->
  match read_env_path "XDG_CACHE_HOME" with
  | Ok dir -> dir/app_name
  | Error _ ->
    match Lazy.force guess_scheme with
    | Linux ->
      let home =
        Logger.try_with get_home
          ~fatal:(fun _ -> Logger.fatal `System "Both XDG_CACHE_HOME and HOME are not set")
      in
      home/".cache"/app_name
    | MacOS ->
      let home =
        Logger.try_with get_home
          ~fatal:(fun _ -> Logger.fatal `System "Both XDG_CACHE_HOME and HOME are not set")
      in
      home/"Library"/"Caches"/app_name
    | Windows ->
      begin
        match read_env_path "LOCALAPPDATA" with
        | Error _ ->
          Logger.fatal `System "Both XDG_CACHE_HOME and LOCALAPPDATA are not set"
        | Ok local_app_data ->
          local_app_data/app_name/"cache"
      end

(** OCaml findlib *)

let findlib_init = lazy begin Findlib.init () end

let get_package_dir pkg =
  Lazy.force findlib_init;
  try
    FilePath.of_string @@ Findlib.package_directory pkg
  with
  | Findlib.No_such_package (pkg, msg) ->
    Logger.fatalf `System "@[<2>No package named `%s':@ %s@]" pkg msg
  | Findlib.Package_loop pkg ->
    Logger.fatalf `System "Package `%s' is required by itself" pkg
