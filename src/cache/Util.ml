let (/) = Filename.concat

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
    Unix.mkdir path 0o777

let mtime path = (Unix.stat path).st_mtime
