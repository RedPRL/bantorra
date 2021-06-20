open StdLabels
module U = UnixLabels
open ResultMonad.Syntax

type filepath = string

let (/) = Filename.concat

let join = List.fold_left ~f:(/) ~init:Filename.current_dir_name

(** Write a string to a file. *)
let writefile p s =
  try
    let ch = open_out_bin p in
    Fun.protect ~finally:(fun () -> close_out_noerr ch) @@
    fun () ->
    output_string ch s;
    close_out ch;
    ret ()
  with Sys_error s -> error @@ `SystemError s

(** Read the entire file as a string. *)
let readfile p =
  try
    let ch = open_in_bin p in
    Fun.protect ~finally:(fun () -> close_in_noerr ch) @@
    fun () ->
    let s = really_input_string ch (in_channel_length ch) in
    close_in ch;
    ret s
  with Sys_error s -> error @@ `SystemError s

(** OCaml implementation of [mkdir -p] *)
let rec ensure_dir path =
  match Sys.is_directory path with
  | false -> error `NotDirectory
  | true -> ret ()
  | exception Sys_error _ ->
    let parent = Filename.dirname path in
    let* () = ensure_dir parent in
    try ret @@ U.mkdir ~perm:0o777 path with
    | U.Unix_error (e, _,  _) -> error @@ `SystemError (U.error_message e)

let protect_cwd f =
  let dir = Sys.getcwd () in
  Fun.protect ~finally:(fun () -> Sys.chdir dir) @@ fun () -> f dir

let normalize_dir dir =
  protect_cwd @@ fun _ -> Sys.chdir dir; Sys.getcwd ()

let parent_of_normalized_dir dir =
  let p = Filename.dirname dir in
  if p = dir then None else Some p

let is_existing_and_regular p =
  try (U.stat p).st_kind = S_REG with _ -> false

let locate_anchor ~anchor start_dir =
  let rec find_root cwd unitpath_acc =
    if is_existing_and_regular anchor then
      Some (cwd, unitpath_acc)
    else
      match parent_of_normalized_dir cwd with
      | None -> None
      | Some parent ->
        Sys.chdir parent;
        find_root parent @@ Filename.basename cwd :: unitpath_acc
  in
  protect_cwd @@ fun _ ->
  find_root (normalize_dir start_dir) []
