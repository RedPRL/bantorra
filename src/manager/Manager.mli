open BantorraBasis

(** {1 Types} *)

type t
(** The type of library managers. *)

type library
(** The abstract type of libraries. *)

type unitpath = string list
(** The type of unit paths. *)

(** {1 Initialization} *)

val init : anchor:string -> routers:(string * Router.t) list -> (t, [> `InvalidRouter of string]) result
(** [init ~anchor ~routers] initiates a library manager for loading libraries.

    @param routers An association list as a mapping from router names to available routers.
    See {!module:Resolver}.
    @param anchor The file name of the library anchors.
*)

(** {1 Library Loading} *)

(** A library is identified by a JSON file in its root directory, which is called "anchor". *)

(** {2 Format of Anchors}

    An anchor can be in one of the following formats:
    {v
{ "format": "1.0.0" }
    v}
    {v
{
  "format": "1.0.0",
  "deps": [
    {
      "mount_point": ["path", "to", "lib1"],
      "router": "router1",
      "router_argument": ...
    },
    {
      "mount_point": ["path", "to", "lib2"],
      "router": "router2",
      "router_argument": ...
    }
  ]
}
    v}

    If the [deps] field is missing, then the library has no dependencies. Each dependency is specified by its mount point in the current library ([mount_point]), the name of the router to find the imported library([router]), and the argument to the router ([router_argument]). During the resolution, the entire JSON subtree under the field [router_argument] is passed to the router. See {!type:Router.router_argument} and {!val:Router.make}.

    The order of entries in [dep] does not matter and the dispatching is based on longest prefix match. If no match can be found, then the unit path is local. The same library can be mounted at multiple points. However, to keep the resolution unambiguous, there cannot be two dependencies sharing the same mount point, and the mount point cannot be the empty list (the root). Here is an example demonstrating the longest prefix match:
    {v
{
  "format": "1.0.0",
  "deps": [
    {
      "mount_point": ["world"],
      "router": "builtin",
      "router_argument": "world"
    },
    {
      "mount_point": ["world", "bantorra"],
      "router": "git",
      "router_argument": {
        "url": "https://github.com/RedPRL/bantorra",
        "branch": "main"
      }
    }
  ]
}
    v}

    The unit path [world.orntorra] will be routed to the unit [orntorra] within the [world] library, pending further resolution, while the unit path [world.bantorra.shisho] will be routed to [shisho] in the library corresponding to [https://github.com/RedPRL/bantorra], not [bantorra.shisho] in the [world] library.

    If some library is mounted at [world.towitorra], then the original unit with the path [world.towitorra] or a path with the prefix [world.towitorra] is no longer accessible. Moreover, [world.towitorra] cannot point to any unit after the mounting because no unit can be associated with the empty path (the root), and [world.towitorra] means the empty path (the root) in the mounted library, which cannot refer to any unit.
*)

val load_library_from_root : t -> File.filepath -> (library, [> `InvalidLibrary of string ]) result
(** [load_library_from_root manager library_root] explicitly loads the library at the directory [library_root]
    from the file system. The loading fails if the anchor file cannot not be founded or is invalid. *)

val load_library_from_route : t ->
  router:string ->
  router_argument:Marshal.value ->
  starting_dir:File.filepath ->
  (library, [> `InvalidLibrary of string ]) result
(** [load_library_from_root ~router ~router_argument ~starting_dir] explicitly loads the library that the router
    [router] is returning with the argument [router_argument] starting at [starting_dir]. (Some routers would
    use the starting directory during the routing.) The loading fails if the routing fails or the anchor file
    could not be founded or is invalid. *)

val load_library_from_route_with_cwd : t ->
  router:string ->
  router_argument:Marshal.value ->
  (library, [> `InvalidLibrary of string ]) result
(** [load_library_from_root ~router ~router_argument] is the same as
    {!val load_library_from_route}[~router ~router_argument ~starting_dir]
    with [starting_dir] being the current working director. *)

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
