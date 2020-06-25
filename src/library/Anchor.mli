open BantorraBasis

type t

type path = string list
type info = Marshal.value
type lib_ref =
  { resolver : string
  ; info : info
  }

val read : string -> t

val iter_lib_refs : (lib_ref -> unit) -> t -> unit

val dispatch_path : t -> path -> (lib_ref * path) option
