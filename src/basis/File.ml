open StdLabels

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
    UnixLabels.mkdir ~perm:0o777 path

let protect_cwd f =
  let dir = Sys.getcwd () in
  match f dir with
  | ans -> Sys.chdir dir; ans
  | exception ext -> Sys.chdir dir; raise ext

let normalize_dir dir =
  protect_cwd @@ fun _ -> Sys.chdir dir; Sys.getcwd ()

let is_existing_and_regular p =
  try (UnixLabels.stat p).st_kind = S_REG with _ -> false

let is_existing_and_directory p =
  try Sys.is_directory p with _ -> false

let is_executable p : bool =
  if Sys.win32 then
    (* One needs to check PATHEXT. *)
    failwith "Please make a PR to improve Windows support."
  else
    try UnixLabels.access p ~perm:[UnixLabels.X_OK]; true with _ -> false

let locate_anchor ~anchor start =
  let rec find_root cwd unitpath_acc =
    if is_existing_and_regular anchor then
      cwd, unitpath_acc
    else
      let parent = Filename.dirname cwd in
      if parent = cwd then
        raise Not_found
      else begin
        Sys.chdir parent;
        find_root parent @@ Filename.basename cwd :: unitpath_acc
      end
  in
  protect_cwd @@ fun _ ->
  Sys.chdir @@ Filename.dirname start;
  find_root (Sys.getcwd ()) []

let locate_anchor_ ~anchor start =
  let rec find_root cwd =
    if is_existing_and_regular anchor then
      cwd
    else
      let parent = Filename.dirname cwd in
      if parent = cwd then
        raise Not_found
      else begin
        Sys.chdir parent;
        find_root parent
      end
  in
  protect_cwd @@ fun _ ->
  Sys.chdir @@ Filename.dirname start;
  find_root (Sys.getcwd ())
