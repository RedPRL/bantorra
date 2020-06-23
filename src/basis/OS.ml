open File

(** The scheme refers to how the default directory should be determined
    when XDG_CONFIG_HOME or XDG_CACHE_HOME is missing.

    It does not correspond to the actual OS that is running. For example, the
    [Linux] scheme covers all BSD-like systems and Cygwin on Windows. *)
type scheme = MacOS | Linux | Windows

let uname_s () =
  try
    let ic = Unix.open_process_args_in "uname" [|"-s"|] in
    let res = String.trim @@ input_line ic in
    Some res
  with
  | _ -> None

let guess_scheme () =
  match Sys.os_type with
  | "Unix" ->
    begin
      match uname_s () with
      | Some "Darwin" -> MacOS
      | _ -> Linux
    end
  | "Cygwin" -> Linux
  | "Win32" -> Windows
  | _ -> Linux

(* XXX I did not really test the following code on different platforms. *)
let get_config_home () =
  match Sys.getenv_opt "XDG_CONFIG_HOME" with
  | Some dir -> dir
  | None ->
    match guess_scheme () with
    | Linux ->
      Sys.getenv "HOME"/".config"
    | MacOS ->
      Sys.getenv "HOME"/"Library"/"Application Support"
    | Windows ->
      Sys.getenv "AppData"
