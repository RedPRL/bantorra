(** {1 Serialization} *)

type value = Json_repr.ezjsonm
(** Type of JSON values. *)

val normalize : value -> value
(** Sort properties of objects by keys, raising errors on duplicate keys. *)

val destruct : 'a Json_encoding.encoding -> value -> 'a
(** [parse str] destructs a JSON value. *)

val parse : 'a Json_encoding.encoding -> string -> 'a
(** [parse str] parses the string [str]. *)

val read : 'a Json_encoding.encoding -> FilePath.t -> 'a
(** [read enc path] reads and parses the content of the file at [path]. *)

val read_url : 'a Json_encoding.encoding -> string -> 'a
(** [read_url enc url] fetches and parses the JSON content at [url] via HTTP Get. *)

val write : ?minify:bool -> 'a Json_encoding.encoding -> FilePath.t -> 'a -> unit
(** [write enc path v] writes the serialization of [v] into the file at [path]. *)

val to_string : value -> string
(** [to_string json] serializes [json] into a compact, minified string. *)
