(**
   The type of JSON values. Please consult the {{:https://www.json.org/json-en.html} JSON standard} and the {{: https://opam.ocaml.org/packages/jsonm/} OCaml package jsonm} for limitations.

    This is intended to be compatible with the {{:https://opam.ocaml.org/packages/ezjsonm/} OCaml package ezjsonm}.
*)
type json_value =
  [ `Null
  | `Bool of bool
  | `Float of float
  | `String of string
  | `A of json_value list
  | `O of (string * json_value) list
  ]

(**
   The type of JSON documents. The top-level must be an array or an object.

   This is intended to be fully compatible with the {{:https://opam.ocaml.org/packages/ezjsonm/} OCaml package ezjsonm}.
*)
type json =
  [ `A of json_value list
  | `O of (string * json_value) list
  ]

module Database :
sig
  type t
  val init : root:string -> t
  val save : t -> unit
  val replace : t -> key:json_value -> value:json -> Digest.t
  val find_opt : t -> key:json_value -> digest:Digest.t option -> json option
end
