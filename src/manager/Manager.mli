(** {1 Types} *)

type t
(** The type of library managers. *)

type library
(** The abstract type of libraries. *)

type unitpath = string list
(** The type of unit paths. *)

type filepath = string
(** The type of file paths. *)

(** {1 Initialization} *)

val init : resolvers:(string * Resolver.t) list -> anchor:string -> t
(** [init ~resolvers ~anchor] initiates a library manager.

    @param resolvers An association list as a mapping from resolver names to available resolvers.
    See {!module:Resolver}.
    @param anchor The file name of the library anchors.
*)

(** {1 Library Loading} *)

val load_library : t -> filepath -> library
(** [load_library manager library_root] explicitly loads the library at the directory [library_root]
    from the file system. By loading, it means the manager retrieves necessary information from the file
    system to resolve unit paths within the library. The intended use of this function is to explicitly
    load the current library via [load_library] and let the manager automatically load dependencies (if any).

    If a library was already loaded, the cached version will be used instead.
    The dependencies are not loaded eagerly. *)

val locate_anchor : anchor:string -> suffix:string -> filepath -> filepath * unitpath
(** [locate_anchor ~anchor ~suffix filepath] assumes the unit at [filepath] resides in some library
    and tries to find the root of the library by locating the file [anchor]. It returns
    the root of the found library and a unit path within the library that could potentially
    point to the input unit. (See the caveat below.)

    This is a helper function to prepare the arguments to {!val:load_library}.

    Note that the returned unit path did not take into account the dependencies that could
    shadow the unit through mounting. For example, if the returned unit path is [["a"; "b"]]
    but there is a dependency mounted at [["a"]], then the original unit is actually not
    accessible by that unit path. This is thus only a retraction of the unit path resolution.
    The application should use {!val:to_unitpath} or {!val:to_filepath} to re-resolve
    the unit path returned by [locate_anchor] instead of assuming that it would point to [filepath].
*)

(** {1 Composite Resolver}

    These functions will automatically load the dependencies.
*)

val to_unitpath : t -> library -> unitpath -> library * unitpath
(** [to_unitpath manager lib unitpath] resolves [unitpath] and returns the {i eventual} library where the unit belongs and the local unit path pointing to the unit.
*)

val to_filepath : t -> library -> unitpath -> suffix:string -> library * filepath
(** [resolver manager lib unitpath ~suffix] resolves [unitpath] in the library [lib] and returns the {i eventual} library where the unit belongs and the corresponding file path of the unit with the specified suffix. It is similar to {!val:to_unitpath} but returns a file path instead of a unit path.

    @param suffix The suffix shared by all the units in the file system.
*)
