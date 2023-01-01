(** Library managers. *)

(** {1 Types} *)

type t
(** The type of library managers. *)

type library
(** The abstract type of libraries. *)

type path = UnitPath.t
(** The type of unit paths. *)

(** {1 Initialization} *)

val init : version:string -> anchor:string -> ?premount:Router.param Trie.t -> Router.t -> t
(** [init ~anchor router] initiates a library manager for loading libraries.

    @param version Format version of anchors and routing-related files.
    @param anchor The file name of the anchors.
    @param premount The pre-mounted routes.
    @param router The router. See {!module:Router}.
*)

(** {1 Library Loading} *)

(** A library is identified by a JSON file in its root directory, which is called an {e anchor}. *)

val load_library_from_root : t -> FilePath.t -> library
(** [load_library_from_root manager lib_root] loads the library at the directory [lib_root]
    from the file system. It is assumed that there is an anchor file is right at [lib_root].

    @param manager The library manager.
    @param lib_root The root of the library, which should be a directory.
    @return The loaded library.
*)

val load_library_from_route : t -> ?starting_dir:FilePath.t -> Router.param -> library
(** [load_library_from_root manager param] loads the library by following the [param].

    @param manager The library manager.
    @param starting_dir The starting directory.
    @param param The route specification, as a JSON value.
    @return The loaded library.
*)

val load_library_from_route_with_cwd : t -> Router.param -> library
(** [load_library_from_root manager param] is
    {!val:load_library_from_route}[ manager ~relative_to:cwd param]
    where [cwd] is the current working directory.
*)

val load_library_from_dir : t -> FilePath.t -> library * path option
(** [load_library_from_dir manager dir] assumes the directory [dir] resides in some library
    and will try to find the root of the library by locating the anchor file.
    It then loads the library marked by the anchor.

    @param manager The library manager.
    @param dir A directory that is assumed to be inside some library.
    @return The loaded library and the unit path
*)

val load_library_from_cwd : t -> library * path option
(** [load_library_from_cwd manager] is {!val:load_library_from_dir}[ manager dir]
    with [dir] being the current working director.
*)

val load_library_from_unit : t -> FilePath.t -> suffix:string -> library * path option
(** [locate_anchor_from_unit filepath ~suffix] assumes [filepath] ends with [suffix]
    and the file at [filepath] resides in some library. It will try to find the root of the library
    and load the library.

    @param manager The library manager.
    @param filepath The corresponding file path.
    @param suffix The suffix of the unit on the file system. Note that the dot is included in the suffix---the suffix of [file.ml] is [.ml], not [ml].
    @return The loaded library and the unit path in the library. The unit path is [None] if the file is actually inaccessible, probably due to another mounted library shadowing the unit.
*)

val library_root : library -> FilePath.t
(** Get the root directory of a library. *)

(** {1 Composite Resolver}

    These functions will automatically load the dependencies.
*)

val resolve :
  t -> ?max_depth:int -> library -> path -> suffix:string -> library * path * FilePath.t
(** [resolve manager lib path ~suffix] resolves [path] in the library in the library [lib] and returns a triple [(lib, upath, fpath)] where [lib] is the {e eventual} library where the unit belongs, [upath] is the unit path in the eventual library [lib], and [fpath] is the corresponding file path with the specified suffix.

    @param manager The library manager.
    @param max_depth Maximum depth for resolving recursive library mounting. The default value is [255].
    @param lib The library.
    @param path The unit path to be resolved.
    @param suffix The suffix shared by all the units in the file system.
*)
