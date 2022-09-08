open BantorraBasis

(** {1 Types} *)

type t
(** The type of library managers. *)

type library
(** The abstract type of libraries. *)

type path = UnitPath.t
(** The type of unit paths. *)

(** {1 Initialization} *)

val init : version:string -> anchor:string -> Router.t -> t
(** [init ~anchor ~routers] initiates a library manager for loading libraries.

    @param version Versioning of the router.
    @param anchor The file name of the anchors.
    @param routers An association list as a mapping from router names to available routers. See {!module:Router}.
*)

(** {1 Library Loading} *)

(** A library is identified by a JSON file in its root directory, which is called "anchor". *)

val load_library_from_root : t -> File.path -> library
(** [load_library_from_root manager lib_root] loads the library at the directory [lib_root]
    from the file system. It is assumed that there is an anchor file is right at [lib_root].

    @param manager The library manager.
    @param lib_root The root of the library, which should be a directory.
    @return The loaded library.
*)

val load_library_from_route : ?hop_limit:int -> t -> lib_root:File.path -> Router.route -> library
(** [load_library_from_root manager ~lib_root route] loads the library by following the [route]
    from the current library at [lib_root].

    @param manager The library manager.
    @param lib_root The starting directory, which is used by some routers ({i e.g.}, the {{:../../BantorraRouters/Waypoint/index.html}Waypoint} routers).
    @param route The route specification, as a JSON value.
    @return The loaded library.
*)

val load_library_from_route_with_cwd : ?hop_limit:int -> t -> Router.route -> library
(** [load_library_from_root manager route] is
    {!val load_library_from_route}[manager ~lib_root route]
    with [lib_root] being the current working director.
*)

val load_library_from_dir : t -> File.path -> library * path option
(** [load_library_from_dir manager dir] assumes the directory [dir] resides in some library
    and will try to find the root of the library by locating the anchor file.
    It then loads the library marked by the anchor.

    @param manager The library manager.
    @param dir A directory that is assumed to be inside some library.
    @return The loaded library and the unit path
*)

val load_library_from_cwd : t -> library * path option
(** [load_library_from_cwd manager] is {!val load_library_from_dir}[manager dir]
    with [dir] being the current working director.
*)

val load_library_from_unit : t -> File.path -> suffix:string -> library * path option
(** [locate_anchor_from_unit filepath ~suffix] assumes [filepath] ends with [suffix]
    and the file at [filepath] resides in some library. It will try to find the root of the library
    and load the library.

    @param manager The library manager.
    @param filepath The corresponding file path.
    @param suffix The suffix of the unit on the file system. Note that the dot is included in the suffix---the suffix of [file.ml] is [.ml], not [ml].
    @return The loaded library and the unit path in the library. The unit path is [None] if the file is actually inaccessible, probably due to another mounted library shadowing the unit.
*)

(** {1 Composite Resolver}

    These functions will automatically load the dependencies.
*)

val resolve :
  t -> ?max_depth:int -> library -> path -> suffix:string -> library * path * File.path
(** [resolve manager lib path ~suffix] resolves [path] in the library in the library [lib] and returns the {e eventual} library where the unit belongs and the corresponding file path with the specified suffix.

    @param manager The library manager.
    @param max_depth Maximum depth for resolving recursive library mounting. The default value is [100].
    @param lib The library.
    @param path The path to be resolved.
    @param suffix The suffix shared by all the units in the file system.
*)
