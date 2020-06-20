open Basis.JSON

type path = string list
type t
val init : root:string -> ?cache_subdir:string -> anchor:string -> t
val init_from_filepath : ?cache_subdir:string -> anchor:string -> suffix:string -> string -> t * path
val to_filepath : t -> suffix:string -> path -> string
val replace_cache : t -> path -> source_digest:Digest.t -> json -> Digest.t
val find_cache_opt : t -> path -> source_digest:Digest.t -> cache_digest:Digest.t option -> json option
