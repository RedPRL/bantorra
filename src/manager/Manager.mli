open BantorraBasis

(** {1 Types} *)

type t
(** The type of library managers. *)

type library
(** The abstract type of libraries. *)

type unitpath = string list
(** The type of unit paths. *)

(** {1 Initialization} *)

val init : anchor:string -> routers:(string * Router.t) list -> (t, [> `InvalidRoutingTable of string]) result
(** [init ~anchor ~routers] initiates a library manager for loading libraries.

    @param routers An association list as a mapping from router names to available routers.
    See {!module:Resolver}.
    @param anchor The file name of the library anchors.
*)

(** {1 Library Loading} *)

val load_library_from_route : t -> Anchor.lib_ref -> (library, [> `InvalidLibrary of string ]) result

val load_library_from_root : t -> File.filepath -> (library, [> `InvalidLibrary of string ]) result
(** [load_library_from_root manager library_root] explicitly loads the library at the directory [library_root]
    from the file system. By loading, it means the manager retrieves necessary information from the file
    system to resolve unit paths within the library. The intended use of this function is to explicitly
    load the current library via [load_library] and let the manager automatically load dependencies (if any).

    If a library was already loaded, the cached version will be used instead.
    The dependencies are not loaded eagerly. *)

val load_library_from_dir : t -> File.filepath -> (library * unitpath option, [> `InvalidLibrary of string ]) result

val load_library_from_cwd : t -> (library * unitpath option, [> `InvalidLibrary of string ]) result

val load_library_from_unit : t -> suffix:string -> File.filepath ->
  (library * unitpath option, [> `InvalidLibrary of string ]) result
(** [locate_anchor_from_unit ~anchor ~suffix filepath] assumes the unit at [filepath] resides in some library
    and tries to find the root of the library by locating the file [anchor]. It returns
    the root of the found library and a unit path within the library that could potentially
    point to the input unit.

    This is a helper function to prepare the arguments to {!val:load_library}.
*)

(** {1 Composite Resolver}

    These functions will automatically load the dependencies.
*)

val resolve : t -> library -> unitpath -> suffix:string ->
  (library * unitpath * string, [ `InvalidLibrary of string | `UnitNotFound of string ]) result
(** [resolve manager lib unitpath ~suffix] resolves [unitpath] in the library [lib] and returns the {i eventual} library where the unit belongs and the corresponding file path of the unit with the specified suffix. It is similar to {!val:to_unitpath} but returns a file path instead of a unit path.

    @param suffix The suffix shared by all the units in the file system.
*)
