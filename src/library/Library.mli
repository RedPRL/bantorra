open BantorraBasis

type path = string list
type t
val init : anchor:string -> root:string -> t
val locate_anchor : anchor:string -> suffix:string -> string -> string * path
val save_state : t -> unit

val iter_deps : (Anchor.lib_name -> unit) -> t -> unit

val to_filepath :
  global:(Anchor.lib_name -> path -> suffix:string -> string) ->
  t -> path -> suffix:string -> string
val replace_cache :
  global:(Anchor.lib_name -> path -> source_digest:Digest.t -> Marshal.t -> Digest.t) ->
  t -> path -> source_digest:Digest.t -> Marshal.t -> Digest.t
val find_cache_opt :
  global:(Anchor.lib_name -> path -> source_digest:Digest.t -> cache_digest:Digest.t option -> Marshal.t option) ->
  t -> path -> source_digest:Digest.t -> cache_digest:Digest.t option -> Marshal.t option
