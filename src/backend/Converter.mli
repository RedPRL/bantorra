(**
   The type of JSON values. Please consult the {{: https://www.json.org/json-en.html} JSON standard} and the {{: https://opam.ocaml.org/packages/jsonm/} OCaml package jsonm} for limitations.

    This is intended to be compatible with the {{: https://opam.ocaml.org/packages/ezjsonm/} OCaml package ezjsonm}.
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

   This is intended to be fully compatible with the {{: https://opam.ocaml.org/packages/ezjsonm/} OCaml package ezjsonm}.
*)
type json =
  [ `A of json_value list
  | `O of (string * json_value) list
  ]

(**
   The converter for {{: https://opam.ocaml.org/packages/lmdb/} OCaml binding of Lightning Memory-Mapped Database (LMDB)} to serialize JSON data.

   Current, the JSON data are encoded through the {{: https://opam.ocaml.org/packages/jsonm/} package jsonm} and then compressed via the zlib bindings in {{: https://opam.ocaml.org/packages/camlzip/} package camlzip}. The error handling is quite weak now, and will be improved later. Unused inputs after a complete JSON document are currently ignored.
*)
val json_conv : json Lmdb.Conv.t

(** The errors from the JSON decoder. *)
exception JsonDecoderError of Jsonm.error
