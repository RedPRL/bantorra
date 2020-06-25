open BantorraBasis

type path = string list
type t
val init : anchor:string -> root:string -> t
val locate_anchor : anchor:string -> suffix:string -> string -> string * path
val save_state : t -> unit

val iter_deps : (Anchor.lib_ref -> unit) -> t -> unit

val to_filepath :
  global:(cur_root:string -> Anchor.lib_ref -> path -> suffix:string -> string) ->
  t -> path -> suffix:string -> string
val replace_cache :
  global:(cur_root:string -> Anchor.lib_ref -> path -> source_digest:Digest.t -> Marshal.t -> Digest.t) ->
  t -> path -> source_digest:Digest.t -> Marshal.t -> Digest.t
val find_cache_opt :
  global:(cur_root:string -> Anchor.lib_ref -> path -> source_digest:Digest.t -> cache_digest:Digest.t option -> Marshal.t option) ->
  t -> path -> source_digest:Digest.t -> cache_digest:Digest.t option -> Marshal.t option
