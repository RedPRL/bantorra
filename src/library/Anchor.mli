(** {1 Types} *)

type t
(** The type of anchors. An anchor marks the root of a library
    and records dependencies on other libraries. See {!val:read}. *)

type unitpath = string list
(** The type of unit paths. *)

type lib_ref =
  { resolver : string (** The name of the library resolver. *)
  ; res_args : Resolver.res_args (** The arguments to the library resolver. *)
  }
(** The type of library references to be resolved. *)

(** {1 Initialization} *)

val read : string -> t
(** [read path] read the content of an anchor file.

    Here is a sample anchor file:
    {v
format: "1.0.0"
deps:
  - mount_point: [lib, num]
    resolver: builtin
    res_args: number
    v}

    The argument format [res_args] is determined by the resolver "[builtin]".
*)

(** {1 Accessors} *)

val iter_deps : (lib_ref -> unit) -> t -> unit
(** [iter_lib_refs f a] runs [f] on each dependency listed in the anchor [a]. *)

val dispatch_path : t -> unitpath -> (lib_ref * unitpath) option
(** [dispatch_path a p] resolves the unit path [p] to [Some (ref, p')] if it points to
    another unit in another library referenced by [ref] and [p'],
    or [None] if it is a local unit path. *)
