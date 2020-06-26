(** {1 Types} *)

type value = Ezjsonm.value
(** The type suitable for marshalling. This is the universal type to exchange information
    within the framework. *)

type yaml = Yaml.yaml
(** The type with access to more YAML features. Currently unused. *)

type t = Ezjsonm.t
(** The type represnting valid JSON documents, which is more restricted than {!type:value}. *)

exception IllFormed
(** The exception indicating errors during encoding, decoding, or I/O. *)

(** {1 Digest} *)

val digest : value -> string
(** A function to generate the digest of a value. *)

(** {1 Compressed Serialization} *)

(** These are functions to store and retrieve something of type [value] on disk. The file format on disk
    is not human-readable. *)

val to_gzip : t -> string
(** A function that serializes a JSON document. *)

val of_gzip : string -> t
(** A function that deserializes a JSON document. *)

val write_gzip : string -> t -> unit
(** [write_gzip path v] writes the serialization of [v] into the file at [path]. *)

val read_gzip : string -> t
(** [read_gzip path v] reads and deserializes the content of the file at [path]. *)

(** {1 Human-Readable Serialization} *)

(** These are functions to store and retrieve something of type [value] on disk
    that is in a human-readable format (YAML). For this reason, the type does not
    need to be a valid JSON document---we can use the type [value] instead of [t].

    They are suitable for reading or generating configuration files
    that can be later modified by normal users. *)

val to_plain : value -> string
(** A function that serializes a value. *)

val of_plain : string -> value
(** A function that deserializes a value. *)

val write_plain : string -> value -> unit
(** [write_plain path v] writes the serialization of [v] into the file at [path]. *)

val read_plain : string -> value
(** [read_plain path v] reads and deserializes the content of the file at [path]. *)

(** {1 Helper Functions} *)

val of_string : string -> value
(** Embedding a string into a [value]. *)

val to_string : value -> string
(** Projecting a string out of a [value]. *)

val of_ostring : string option -> value
(** Embedding an optional string into a [value]. *)

val to_ostring : value -> string option
(** Projecting an optional string out of a [value]. *)

val of_list : ('a -> value) -> 'a list -> value
(** Embedding a list into a [value]. *)

val to_list : (value -> 'a) -> value -> 'a list
(** Projecting a list out of a [value]. *)

val of_float : float -> value
(** Embedding a string into a [value]. *)

val to_float : value -> float
(** Projecting a list out of a [value]. *)

val dump : value -> string
(** A quick, dirty converter to turn a [value] into a string for ugly-printing. *)
