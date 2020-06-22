type t

type path = string list
type lib_name =
  { name : string
  ; version : string option
  }

val read : string -> t

val iter_lib_names : (lib_name -> unit) -> t -> unit

val dispatch_path : t -> path -> (lib_name * path) option
