open BantorraBasis

(** {1 Types} *)

type t
(** The type of library managers. *)

type unitpath = string list
(** The type of unit paths. *)

(** {1 Initialization} *)

val init : resolvers:(string * Resolver.t) list -> anchor:string -> cur_root:string -> t
(** [init ~resolvers ~anchor ~cur_root] initiates a library manager.

    @param resolvers An associated list of available global resolvers. See {!module:Resolver}.
    @param anchor The file name of the library anchors.
    @param cur_root The root of the starting library.
*)

val save_state : t -> unit
(** Save the current state into disk. *)

val locate_anchor : anchor:string -> suffix:string -> string -> string * unitpath
(** Reexported {!val:BantorraLibrary.Library.locate_anchor} for convenience. It locates the
    root of the current library for initializing a library manager. *)

(** {1 Accessors} *)

val to_filepath : t -> unitpath -> suffix:string -> string
(** [to_filepath m unitpath ~suffix] turns a unit path into a file path appended with [suffix]. *)

val replace_cache : t -> unitpath -> source_digest:Digest.t -> Marshal.t -> Digest.t
(** [replace_cache m unitpath ~source_digest value] replaces the cached content associated with [unitpath] and
    [source_digest] with [value]. It returns the digest of the stored cache. *)

val find_cache_opt : t -> unitpath -> source_digest:Digest.t -> cache_digest:Digest.t option -> Marshal.t option
(** [find_cache_opt m unitpath ~source_digest ~cache_digest value] finds the cached content associated with [unitpath] and
    [source_digest]. If [cache_digest] is [None], it means the digest checking is skipped. One should use the digest
    returned by [replace_cache] whenever possible. *)
