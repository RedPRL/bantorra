(** {1 Serialization} *)

type value = Json_repr.ezjsonm
(** Type of JSON values. *)

val normalize : value -> value
(** Sort properties of objects by names, erring on duplicate property keys. *)

val destruct : 'a Json_encoding.encoding -> value -> 'a

val read : 'a Json_encoding.encoding -> FilePath.t -> 'a
(** [read enc path] reads and deserializes the content of the file at [path]. *)

val write : ?minify:bool -> 'a Json_encoding.encoding -> FilePath.t -> 'a -> unit
(** [write enc path v] writes the serialization of [v] into the file at [path]. *)

val to_string : value -> string
(** [to_string json] serializes [json] into a compact, minified string. *)
