(** {1 Types} *)

type value = Ezjsonm.value
(** The type suitable for marshalling. This is the universal type to exchange information
    within the framework. *)

(** {1 Serialization} *)

val of_json : string -> (value, [> `FormatError of string]) result
(** A function that deserializes a value. *)

val read_json : string -> (value, [> `FormatError of string | `SystemError of string ]) result
(** [read_json path v] reads and deserializes the content of the file at [path]. *)

val to_json : ?minify:bool -> value -> string
(** A function that serializes a value. *)

val write_json : ?minify:bool -> string -> value -> (unit, [> `FormatError of string | `SystemError of string]) result
(** [unsafe_write_json path v] writes the serialization of [v] into the file at [path]. *)

(** {1 Helper Functions} *)

val of_string : string -> value
(** Embedding a string into a {!type:value}. *)

val to_string : value -> (string, [> `FormatError of string]) result
(** Projecting a string out of a {!type:value}. *)

val of_ostring : string option -> value
(** Embedding an optional string into a {!type:value}. *)

val to_ostring : value -> (string option, [> `FormatError of string]) result
(** Projecting an optional string out of a {!type:value}. *)

val of_list : ('a -> value) -> 'a list -> value
(** Embedding a list into a {!type:value}. *)

val to_list : (value -> ('a, [> `FormatError of string] as 'e) result) -> value -> ('a list, 'e) result
(** Projecting a list out of a {!type:value}. *)

val of_olist : ('a -> value) -> 'a list option -> value
(** Embedding an optional list into a {!type:value}. *)

val to_olist : (value -> ('a, [> `FormatError of string] as 'e) result) -> value -> ('a list option, 'e) result
(** Projecting an optional list out of a {!type:value}. *)

val parse_object :
  ?required:string list -> ?optional:string list -> value ->
  ((string * value) list * (string * value) list, [> `FormatError of string ]) result
(** Projecting an associative list out of a {!type:value}.

    @param required Names of required fields. By default, it is [[]].
    @param optional Names of optional fields. By default, it is [[]].
    @return A pair of an associative list for required fields and that for optional fields. Missing optional fields will be associated with [`Null]. In other words, a missing ["opt"] field in a JSON object is treated as ["opt": null].
*)

val parse_object_or_null :
  ?required:string list -> ?optional:string list -> value ->
  (((string * value) list * (string * value) list) option, [> `FormatError of string ]) result
(** Projecting an optional associative list out of a {!type:value}. See {!val:parse_object}. *)

val dump : Format.formatter -> value -> unit
(** An ugly-printer for {!type:value}. *)
