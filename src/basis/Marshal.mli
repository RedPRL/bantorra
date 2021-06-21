(** {1 Types} *)

type value = Ezjsonm.value
(** The type suitable for marshalling. This is the universal type to exchange information
    within the framework. *)

(** {1 Human-Readable Serialization} *)

(** These are functions to retrieve the data of type [value] in the JSON format.
    They are suitable for reading configuration files created by users. *)

val of_json : string -> (value, [> `FormatError of string]) result
(** A function that deserializes a value. *)

val read_json : string -> (value, [> `FormatError of string | `SystemError of string ]) result
(** [read_json path v] reads and deserializes the content of the file at [path]. *)

(** {2 Unsafe API} *)

val to_json : ?minify:bool -> value -> string
(** A function that serializes a value. This function does not quote strings properly due to a bug in the [json] package. *)

val write_json : ?minify:bool -> string -> value -> (unit, [> `FormatError of string | `SystemError of string]) result
(** [unsafe_write_json path v] writes the serialization of [v] into the file at [path]. This function does not quote strings properly due to a bug in the [json] package. *)

(** {1 Helper Functions} *)

val invalid_arg : f:string -> value -> ('a, unit, string, ('b, [> `FormatError of string ]) result) format4 -> 'a

val of_string : string -> value
(** Embedding a string into a [value]. *)

val to_string : value -> (string, [> `FormatError of string]) result
(** Projecting a string out of a [value]. *)

val of_ostring : string option -> value
(** Embedding an optional string into a [value]. *)

val to_ostring : value -> (string option, [> `FormatError of string]) result
(** Projecting an optional string out of a [value]. *)

val of_list : ('a -> value) -> 'a list -> value
(** Embedding a list into a [value]. *)

val to_list : (value -> ('a, [> `FormatError of string] as 'e) result) -> value -> ('a list, 'e) result
(** Projecting a list out of a [value]. *)

val of_olist : ('a -> value) -> 'a list option -> value

val to_olist : (value -> ('a, [> `FormatError of string] as 'e) result) -> value -> ('a list option, 'e) result

val dump : value -> string
(** A quick, dirty converter to turn a [value] into a string for ugly-printing. *)

val parse_object_fields :
  ?required:string list -> ?optional:string list -> (string * value) list ->
  ((string * value) list * (string * value) list, [> `FormatError of string ]) result
