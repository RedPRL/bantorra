open Basis.JSON

type t
type path = string list

val locate_anchor_and_init : anchor_path:string -> suffix:string -> string -> t * path

val replace_cache : t -> path -> source_digest:Digest.t -> json -> Digest.t
val find_cache_opt : t -> path -> source_digest:Digest.t -> cache_digest:Digest.t option -> json option
