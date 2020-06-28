(** {1 Types} *)

type t
(** The type of library managers. *)

type library
(** The abstract type of libraries. *)

type unitpath = string list
(** The type of unit paths. *)

(** {1 Initialization} *)

val init : resolvers:(string * Resolver.t) list -> anchor:string -> t
(** [init ~resolvers ~anchor] initiates a library manager.

    @param resolvers An association list of available global resolvers. See {!module:Resolver}.
    @param anchor The file name of the library anchors.
*)

(** {1 Library Loading} *)

val load_library : t -> string -> library
(** [load_library manager root] loads the library at [root]. *)

val locate_anchor : anchor:string -> suffix:string -> string -> string * unitpath
(** [locate_anchor ~anchor ~suffix path] assumes the unit at [path] resides in some library
    and tries to find the root of the library by locating the file [anchor]. It returns
    the root of the found library and a unit path within the library that could potentially
    point to the input unit. (See the caveat below.)

    This is a helper function to prepare the arguments to {!val:load_library}.

    Note that the returned unit path did not take into account the dependencies that could
    shadow the unit through mounting. For example, if the returned unit path is [["a"; "b"]]
    but there is a dependency mounted at [["a"]], then the original unit is actually not accessible by that path.
*)

(** {1 Resolver}

    These accessors will automatically load the dependencies.
*)

val resolve : t -> library -> unitpath -> suffix:string -> library * string
(** [resolver manager lib unitpath ~suffix] resolves [unitpath] in the library [lib] and returns the eventual library where the unit belong and the underlying file path of the unit.

    @param suffix The suffix shared by all the units in the file system.
*)
