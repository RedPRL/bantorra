open BantorraBasis

(** {1 Types} *)

type unitpath = Anchor.unitpath
(** The type of unit paths. *)

type t
(** The type of libraries. *)

(** {1 Initialization} *)

val init : anchor:string -> root:string -> t
(** Initite a library rooted at [root] where the name of the anchor file is [anchor]. *)

val save_state : t -> unit
(** Save the current state into disk. *)

(** {1 Accessor} *)

val iter_deps : (Anchor.lib_ref -> unit) -> t -> unit
(** Save the current state into disk. *)

(** {1 Hooks for Library Management} *)

(** The following API is for a library manager to chain all the libraries together.
    Please use the high-level API in {{:../../Bantorra/Manager/index.html}BantorraManager.Manager} instead. *)

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
