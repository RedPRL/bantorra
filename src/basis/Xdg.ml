open File

(** The scheme refers to how the default directory should be determined
    when XDG_CONFIG_HOME or XDG_CACHE_HOME is missing.

    It does not correspond to the actual OS that is running. For example, the
    [Linux] scheme covers all BSD-like systems and Cygwin on Windows. *)
type scheme = MacOS | Linux | Windows

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

(* XXX I did not test the following code on different platforms. *)
let get_config_home ?(as_linux=false) ~app_name =
  match Sys.getenv_opt "XDG_CONFIG_HOME" with
  | Some dir -> dir/app_name
  | None ->
    match Lazy.force guess_scheme, as_linux with
    | Linux, _ | _, true ->
      Sys.getenv "HOME"/".config"/app_name
    | MacOS, false ->
      Sys.getenv "HOME"/"Library"/"Application Support"/app_name
    | Windows, false ->
      Sys.getenv "APPDATA"/app_name/"config"

(* XXX I did not test the following code on different platforms. *)
let get_cache_home ?(as_linux=false) ~app_name =
  match Sys.getenv_opt "XDG_CACHE_HOME" with
  | Some dir -> dir/app_name
  | None ->
    match Lazy.force guess_scheme, as_linux with
    | Linux, _ | _, true ->
      Sys.getenv "HOME"/".cache"/app_name
    | MacOS, false ->
      Sys.getenv "HOME"/"Library"/"Caches"/app_name
    | Windows, false ->
      Sys.getenv "LOCALAPPDATA"/app_name/"cache"
