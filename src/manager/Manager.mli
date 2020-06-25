open BantorraBasis

type t
type path = string list

val init : resolvers:(string * Resolver.t) list -> anchor:string -> root:string -> t
val save_state : t -> unit

val to_filepath : t -> path -> suffix:string -> string
val replace_cache : t -> path -> source_digest:Digest.t -> Marshal.t -> Digest.t
val find_cache_opt : t -> path -> source_digest:Digest.t -> cache_digest:Digest.t option -> Marshal.t option
