(** {1 Serialization} *)

val read : 'a Json_encoding.encoding -> File.path -> 'a
(** [read enc path] reads and deserializes the content of the file at [path]. *)

val write : ?minify:bool -> 'a Json_encoding.encoding -> File.path -> 'a -> unit
(** [write enc path v] writes the serialization of [v] into the file at [path]. *)

val serialize : ?minify:bool -> 'a Json_encoding.encoding -> 'a -> string
(** [serialize] is like [write], but returning the string instead of writing it to a file. *)
