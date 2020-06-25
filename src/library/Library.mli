open BantorraBasis

type unitpath = Anchor.unitpath
(** The type of unit paths. *)

type t
(** The type of libraries. *)

val init : anchor:string -> root:string -> t
(** Initite a library rooted at [root] where the name of the anchor file is [anchor]. *)

val locate_anchor : anchor:string -> suffix:string -> string -> string * unitpath
(** [locate_anchor ~anchor ~suffix path] assumes the unit at [path] resides in some library
    and tries to find the root of the library by locating the file [anchor]. It returns
    the root of the found library and a unit path within the library that could point
    to the input unit.

    Note that the returned unit paths did not consider the dependencies that could be
    mounted on the path. That is, if the unit path is [["a"; "b"]] but there is a dependency
    mounted at [["a"]], then the original unit is not accessible.
*)

val save_state : t -> unit
(** Save the current state into disk. *)

val iter_deps : (Anchor.lib_ref -> unit) -> t -> unit
(** Save the current state into disk. *)

val to_filepath :
  global:(cur_root:string -> Anchor.lib_ref -> unitpath -> suffix:string -> string) ->
  t -> unitpath -> suffix:string -> string
(** [to_filepath ~global lib unitpath ~suffix] turns a unit path into a file path appended with [suffix].

    @param global The global resolver for unit paths pointing to other libraries.
*)

val replace_cache :
  global:(cur_root:string -> Anchor.lib_ref -> unitpath -> source_digest:Digest.t -> Marshal.t -> Digest.t) ->
  t -> unitpath -> source_digest:Digest.t -> Marshal.t -> Digest.t
(** [replace_cache ~global lib unitpath ~source_digest value] replaces the cache associated with [unitpath] and
    [source_digest] with [value]. It returns the digest of the stored cache.

    @param global The global cache replacer for unit paths pointing to other libraries.
    @param source_digest The digest of the source file. For example, [.agda] files in the Agda system.
*)

val find_cache_opt :
  global:(cur_root:string -> Anchor.lib_ref -> unitpath -> source_digest:Digest.t -> cache_digest:Digest.t option -> Marshal.t option) ->
  t -> unitpath -> source_digest:Digest.t -> cache_digest:Digest.t option -> Marshal.t option
(** [find_cache ~global lib unitpath ~source_digest ~cache_digest value] finds the cache associated with [unitpath] and
    [source_digest]. If [cache_digest] is [None], it means the digest checking is skipped. One should use the digest
    returned by [replace_cache] whenever possible.

    @param global The global cache finder for unit paths pointing to other libraries.
    @param source_digest The digest of the source file. For example, [.agda] files in the Agda system.
    @param cache_digest The digest of the stored cache. For example, [.agdai] files in the Agda system.
*)
