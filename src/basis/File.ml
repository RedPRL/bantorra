let (/) p q =
  if Filename.is_relative q then
    Filename.concat p q
  else
    q

(** Write a string to a file. *)
let writefile p s =
  let ch = open_out_bin p in
  try
    output_string ch s;
    close_out ch
  with Sys_error _ as e ->
    close_out_noerr ch;
    raise e

let writefile_noerr p s =
  try writefile p s with _ -> ()

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

let protect_cwd f =
  let dir = Sys.getcwd () in
  match f dir with
  | ans -> Sys.chdir dir; ans
  | exception ext -> Sys.chdir dir; raise ext

let is_existing_and_regular p =
  try (Unix.stat p).st_kind = S_REG with _ -> false
