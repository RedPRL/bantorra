open BantorraBasis

type info = Marshal.value
type t

val make :
  ?checker:(cur_root:string -> info -> bool) ->
  ?info_dumper:(cur_root:string -> info -> string) ->
  (cur_root:string -> info -> string option) ->
  t

val resolve : t -> cur_root:string -> info -> string
val resolve_opt : t -> cur_root:string -> info -> string option
val check : t -> cur_root:string -> info -> bool
val dump_info : t -> cur_root:string -> info -> string
