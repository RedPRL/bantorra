open BantorraBasis

type info = Marshal.value
type t

val make :
  ?fast_checker:(cur_root:string -> info -> bool) ->
  ?args_dumper:(cur_root:string -> info -> string) ->
  (cur_root:string -> info -> string option) ->
  t

val resolve : t -> cur_root:string -> info -> string
val resolve_opt : t -> cur_root:string -> info -> string option
val fast_check : t -> cur_root:string -> info -> bool
val dump_args : t -> cur_root:string -> info -> string
