open BantorraBasis

type info = Marshal.value
type t

val make :
  ?checker:(info -> bool) ->
  ?info_dumper:(info -> string) ->
  (info -> string option) ->
  t

val resolve : t -> info -> string
val resolve_opt : t -> info -> string option
val check : t -> info -> bool
val dump_info : t -> info -> string
