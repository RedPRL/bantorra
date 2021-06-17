open StdLabels

type filepath = string

let (/) = Filename.concat

let join = List.fold_left ~f:(/) ~init:Filename.current_dir_name

(** Write a string to a file. *)
let writefile p s =
  let ch = open_out_bin p in
  try
    output_string ch s;
    close_out ch
  with Sys_error _ as e ->
    close_out_noerr ch;
    raise e

(** Read the entire file as a string. *)
let readfile p =
  let ch = open_in_bin p in
  try
    let s = really_input_string ch (in_channel_length ch) in
    close_in ch;
    s
  with Sys_error _ as e ->
    close_in_noerr ch;
    raise e

(** OCaml implementation of [mkdir -p] *)
let rec ensure_dir path =
  match Sys.is_directory path with
  | false -> raise @@ Sys_error (path ^ ": Not a directory")
  | true -> ()
  | exception Sys_error _ ->
    let parent = Filename.dirname path in
    ensure_dir parent;
    UnixLabels.mkdir ~perm:0o777 path

let protect_cwd f =
  let dir = Sys.getcwd () in
  Fun.protect ~finally:(fun () -> Sys.chdir dir) @@ fun () -> f dir

let normalize_dir dir =
  protect_cwd @@ fun _ -> Sys.chdir dir; Sys.getcwd ()

let parent_of_normalized_dir dir =
  let p = Filename.dirname dir in
  if p = dir then None else Some p

let is_existing_and_regular p =
  try (UnixLabels.stat p).st_kind = S_REG with _ -> false

let locate_anchor ~anchor start_dir =
  let rec find_root cwd unitpath_acc =
    if is_existing_and_regular anchor then
      cwd, unitpath_acc
    else
      match parent_of_normalized_dir cwd with
      | None -> raise Not_found
      | Some parent ->
        Sys.chdir parent;
        find_root parent @@ Filename.basename cwd :: unitpath_acc
  in
  protect_cwd @@ fun _ ->
  find_root (normalize_dir start_dir) []
