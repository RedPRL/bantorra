module E = Error

type t = Fpath.t (* must be an absolute, normalized path (no . or ..) *)

let equal = Fpath.equal

let compare = Fpath.compare

let is_root = Fpath.is_root

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

let of_fpath ?cwd p =
  let p = match cwd with None -> p | Some cwd -> Fpath.append cwd p in
  let p = Fpath.normalize p in
  if Fpath.is_abs p then
    p
  else
    E.fatalf `System "File path `%a' is not absolute" Fpath.pp p

let to_fpath p = p

let of_string ?cwd p =
  match Fpath.of_string p with
  | Error (`Msg msg) -> E.fatalf `System "Cannot parse file path `%s': %s" (String.escaped p) msg
  | Ok p -> of_fpath ?cwd p

let pp = Fpath.pp
