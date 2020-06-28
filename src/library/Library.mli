(** {1 Types} *)

type unitpath = Anchor.unitpath
(** The type of unit paths. *)

type t
(** The type of libraries. *)

(** {1 Initialization} *)

val init : anchor:string -> root:string -> t
(** Initite a library rooted at [root] where the name of the anchor file is [anchor]. *)

val locate_anchor : anchor:string -> suffix:string -> string -> string * unitpath
(** See {!val:Manager.locate_anchor}. *)

(** {1 Accessor} *)

val iter_deps : (Anchor.lib_ref -> unit) -> t -> unit
(** Iterate over all dependencies listed in the anchor. *)

(** {1 Hooks for Library Managers} *)

(** The following API is for a library manager to chain all the libraries together.
    Please use the high-level API in {!module:Manager} instead. *)

val resolve :
  global:(cur_root:string -> Anchor.lib_ref -> unitpath -> suffix:string -> t * string) ->
  t -> unitpath -> suffix:string -> t * string
(** [resolve ~global lib unitpath ~suffix] resolves [unitpath] and returns the eventual library where the unit belong and the underlying file path of the unit.

    @param global The global resolver for unit paths pointing to other libraries.
    @param suffix The suffix shared by all the units in the file system.
*)
