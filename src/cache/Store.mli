open BantorraBasis

(** {1 Types} *)

type t
(** The type of cache stores. *)

(** {1 Initialization} *)

val init : root:string -> t
(** [init ~root] initialize the store rooted at [root]. It assumes it has exclusive control
    over the files and directories under [root].

    @param root The root directory of the cache store. It is assumed that the directory already exists.
*)

val save_state : t -> unit
(** [save_state s] saves the current state of the cache back to the disk. *)

(** {1 Accessors} *)

val replace_item : t -> key:Marshal.value -> value:Marshal.t -> Digest.t
(** [replace_item s ~key ~value] saves the content to disk and return a digest that
    can be used in [find_item_opt]. It overwrites the content indexed by the same [key]. *)

val digest_of_item : key:Marshal.value -> value:Marshal.t -> Digest.t
(** [digest_of_item ~key ~value] calculates the same digest {e as if} {!val:replace_item}
    would have returned without touching the store.
    This is useful when the cache is disabled but the digest is still needed.
    (Currently, the option to disable cache is not implemented.) *)

val find_item_opt : t -> key:Marshal.value -> digest:Digest.t option -> Marshal.t option
(** [find_item_opt s ~key ~digest:(Some digest)] tries to retrieve the cached result
    indexed by the [key]. The content will be checked against the provided digest.
    [find_opt db ~key ~digest:None] is the same except that it skips the digest
    checking.

    @return [None] if there is no applicable cache or there is an error during decoding.
    @return [Some j] if the cached result is [j].
*)
