module E = Error

type t = string list (* all segments must be non-empty and satisfy Fpath.is_seg *)

let equal = List.equal String.equal

let compare = List.compare String.compare

let root : t = []

let is_root l = l = root

let is_seg s = s <> "" && Fpath.is_seg s && not (Fpath.is_rel_seg s)

let assert_seg s =
  if not (is_seg s) then
    E.fatalf `InvalidLibrary "%s not a valid unit segment" s

let of_seg s = assert_seg s; [s]

let add_seg u s = assert_seg s; u @ [s]

let prepend_seg s u = assert_seg s; s :: u

let to_list l = l

let of_list l = List.iter assert_seg l; l

let of_string p =
  E.tracef "UnitPath.of_string(%s)" p @@ fun () ->
  if p = "." then []
  else of_list @@ String.split_on_char '/' p

let to_string =
  function
  | [] -> "."
  | l -> String.concat "/" l

let pp fmt l = Format.pp_print_string fmt (to_string l)

let unsafe_of_list l = l
