open BantorraBasis

type path = string list
type t
val init : root:string -> anchor:string -> t
val locate_anchor_and_init : anchor:string -> suffix:string -> string -> t * path
val save_cache : t -> unit

val iter_deps : (Anchor.lib_name -> unit) -> t -> unit

val to_local_filepath : t -> path -> suffix:string -> string
val replace_local_cache : t -> path -> source_digest:Digest.t -> Marshal.t -> Digest.t
val find_local_cache_opt : t -> path -> source_digest:Digest.t -> cache_digest:Digest.t option -> Marshal.t option

val to_filepath :
  global:(Anchor.lib_name -> path -> suffix:string -> string) ->
  t -> path -> suffix:string -> string
val replace_cache :
  global:(Anchor.lib_name -> path -> source_digest:Digest.t -> Marshal.t -> Digest.t) ->
  t -> path -> source_digest:Digest.t -> Marshal.t -> Digest.t
val find_cache_opt :
  global:(Anchor.lib_name -> path -> source_digest:Digest.t -> cache_digest:Digest.t option -> Marshal.t option) ->
  t -> path -> source_digest:Digest.t -> cache_digest:Digest.t option -> Marshal.t option
