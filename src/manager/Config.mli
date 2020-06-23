type t

type lib_name = BantorraLibrary.Anchor.lib_name

val init : app_name:string -> t

val length_libs : t -> int
val mem_libs : t -> lib_name -> bool
val find_libs : t -> lib_name -> string
