open Basis
open Basis.File

let state_file = "state"
let data_subdir = "data"

type t =
  { root: string
  ; state: State.t
  }

let read_state ~root =
  try State.of_json @@ JSON.readfile (root/state_file) with _ -> State.init ()

let init ~root =
  ensure_dir (root/data_subdir);
  {root; state = read_state ~root}

let save {root; state} =
  JSON.writefile (root/state_file) @@ State.to_json state

let replace_item {root; state} ~key ~value =
  let key = JSON.digest_of_value key
  and value = JSON.to_gzip value in
  writefile (root/data_subdir/key) value;
  State.update_atime state ~key;
  Digest.string value

let check_digest d s =
  match d with
  | None -> ()
  | Some d -> if Digest.string s <> d then failwith "Digest not matched"

let find_item_opt {root; state} ~key ~digest =
  let key = JSON.digest_of_value key in
  try
    let value = readfile @@ root/data_subdir/key in
    check_digest digest value;
    let value = JSON.of_gzip value in
    State.update_atime state ~key;
    Some value
  with
  | _ -> None
