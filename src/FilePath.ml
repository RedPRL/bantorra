module E = Error

type t = Fpath.t (* must be an absolute, normalized path (no . or ..) *)

let equal = Fpath.equal

let compare = Fpath.compare

let is_root = Fpath.is_root

let is_dir_path = Fpath.is_dir_path

let to_dir_path = Fpath.to_dir_path

let parent = Fpath.parent

let basename = Fpath.basename

let has_ext = Fpath.has_ext

let rem_ext ext = Fpath.rem_ext ext

let add_ext = Fpath.add_ext

let add_unit_seg p s =
  UnitPath.assert_seg s;
  Fpath.add_seg p s

let append_unit p u =
  if UnitPath.is_root u then p else
    Fpath.append p (Fpath.v @@ UnitPath.to_string u)

let of_fpath ?relative_to ?expanding_tilde p =
  let p =
    match relative_to with
    | None -> p
    | Some relative_to -> Fpath.append relative_to p
  in
  let p = Fpath.normalize p in
  if Fpath.is_abs p then
    p
  else
    let p_str = Fpath.to_string p in
    if p_str == "~" || String.starts_with ~prefix:"~/" p_str then
      match expanding_tilde with
      | None -> E.fatalf `System "Tilde expansion was not enabled for the file path `%a'" Fpath.pp p
      | Some home ->
        Fpath.v (Fpath.to_string home ^ String.sub p_str 1 (String.length p_str - 1))
    else
      E.fatalf `System "File path `%a' is not absolute" Fpath.pp p

let to_fpath p = p

let of_string ?relative_to ?expanding_tilde p =
  match Fpath.of_string p with
  | Error (`Msg msg) -> E.fatalf `System "Cannot parse file path `%s': %s" (String.escaped p) msg
  | Ok p -> of_fpath ?relative_to ?expanding_tilde p

let to_string = Fpath.to_string

let dump = Fpath.pp

let pp ~relative_to fmt p =
  let p =
    match Fpath.relativize ~root:relative_to p with
    | None -> p
    | Some p -> p
  in
  Fpath.pp fmt p
