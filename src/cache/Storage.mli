(**
   The type of JSON values. Please consult the {{: https://www.json.org/json-en.html} JSON standard} and the {{: https://opam.ocaml.org/packages/jsonm/} OCaml package jsonm} for limitations.

    This is intended to be compatible with the {{: https://opam.ocaml.org/packages/ezjsonm/} OCaml package ezjsonm}.
*)
type json_value = Ezjsonm.value

(**
   The type of JSON documents. The top-level must be an array or an object.

   This is intended to be fully compatible with the {{: https://opam.ocaml.org/packages/ezjsonm/} OCaml package ezjsonm}.
*)
type json = Ezjsonm.t

type t
val init : root:string -> t
val replace : t -> key:json -> value:json -> Digest.t
val find_opt : t -> key:json -> digest:Digest.t option -> json option
