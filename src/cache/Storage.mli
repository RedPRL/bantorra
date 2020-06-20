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
  (** type of database handles *)
  type t

  (** [init ~root] initialize the database rooted at [root].

      @param root The root directory of the database. If not existing, it will be created.
  *)
  val init : root:string -> t

  (** [save db] saves the state of the database back to the disk. *)
  val save : t -> unit

  (** [replace_item db ~key ~value] saves the content on disk and return a digest that
      can be used in [find_item_opt]. It overwrites the content indexed by the same [key]. *)
  val replace_item : t -> key:json_value -> value:json -> Digest.t

  (** [find_item_opt db ~key ~digest:(Some digest)] tries to retrive the cached result
      indexed by the [key]. The content will be checked against the provided digest.
      [find_opt db ~key ~digest:None] is the same except that it skips the digest
      checking.

      @return The function returns [None] if there is no applicable cache or there is an error during decoding.
      @return [Some j] The cached result is [j].
  *)
  val find_item_opt : t -> key:json_value -> digest:Digest.t option -> json option
end
