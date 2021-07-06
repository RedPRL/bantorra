(**
   A {e library} in the Bantorra framework is a tree of units that can be accessed via unit paths from the root. A unit path is a list of string separated by the dot, such as [std.num.types]. The purpose of the Bantorra framework is to provide a flexible mechanism to map each unit path to some underlying file path. For example, the unit path [std.num.types] might be mapped to the file path [/usr/lib/built-in/number/types.source], and the resolution process takes in both what is provided by the application and what is provided by its users.
*)

(**
   {1 Introduction}

   In the simplest case, there is a one-to-one correspondence between units and files under a directory: the unit path [a.b.c] corresponds to the file [a/b/c.source] where [.source] is the extension specified by the application. The root directory is marked by special files called {e anchor}, which are files with a fixed name again specified by the application. For example, the existence of a [dune] file means there is an OCaml library in the eyes of the [dune] building tool. An anchor in the Bantorra framework marks the existence of a library. For example, if the anchor file name is [.lib], an anchor file at [/usr/lib/built-in/number/.lib] means there is a library containing files under [/usr/lib/built-in/number].

   It is common for units within a library to access units in another library. To do so, an anchor may {e mount} a library in the tree, in a way similar to how partitions are mounted in POSIX-compliant systems. Here is a sample anchor file:
   {v
{
  "format": "1.0.0",
  "depends": [
    {
      "mount_point": ["std"; "num"],
      "router": "builtin",
      "router_argument": "number"
    }
  ]
}
    v}
   The above anchor file mounts the library [number] at [std.num] via the [builtin] router. With this, the unit path [std.num.types] will be routed as the unit path [types] within the library [number]. The [builtin] router is responsible for locating the root of this [number] library in the file system. The resolution is recursive because the mounted library may mount yet another library.

   The implementation of the [builtin] router is specified by the application. The application could use a fixed table router to implement the [builtin] router, but it could also specify any other router that takes in the argument (which is marshalled as a JSON value). A few basic routers are provided in {{:../BantorraRouters/index.html}BantorraRouters}.

   A Bantorra library manager holds the mapping from router names (such as [builtin]) to their implimentations (such as the fixed table) and is responsible for loading libraries. The manager is the entry point of the Bantorra framework---one should always start with a library manager and use it to load libraries. Here is an example:
   {[
     open Bantorra
     open BantorraRouters

     (* Create a fixed table router, ignoring errors. *)
     let builtin = Result.get_ok @@
       FixedTable.router ~dict:["number", "/usr/lib/built-in/number/"]

     (** Get a library manager (ignoring error handling). *)
     let manager = Result.get_ok @@
       Manager.init ~anchor:".lib" ~routers:["builtin", builtin]

     (** Load the library where the current directory belongs. *)
     let lib_cwd, _ = Result.get_ok @@ Manager.load_library_from_cwd manager

     (** Load a library using the [builtin] router. *)
     let lib_number = Result.get_ok @@
       Manager.load_library_from_route manager
         (* Name of the router. *)
         ~router:"builtin"
         (* The argument sent to the router, as a JSON value. *)
         ~router_argument:(`String "number")
         (* Some routers take the starting directory into consideration. *)
         ~starting_dir:(Sys.getcwd ())

     (** Directly load the library from its root without using any routing.
         (The manager will return the same library.) *)
     let lib_number2 = Result.get_ok @@
       Manager.load_library_from_root manager "/usr/lib/built-in/number/"

     (** Resolve a unit path and get its location in the file system. *)
     let _local_lib, _local_unitpath, _filepath = Result.get_ok @@
       Manager.resolve manager lib_number ["types"] ~suffix:".source"

     (** Resolve the same unit path but with a different suffix. *)
     let _local_lib, _local_unitpath, _filepath = Result.get_ok @@
       Manager.resolve manager lib_number ["types"] ~suffix:".compiled"

     (** Resolve another unit path and get its location in the file system.
         The result is the same as above, assuming that the library represented
         by [lib_number] is mounted at [std.num]. *)
     let local_lib2, local_path2, filepath2 = Result.get_ok @@
       Manager.resolve manager lib_cwd ["std"; "num"; "types"] ~suffix:".compiled"
   ]}

   As shown above, the application can specify an arbitrary mapping from router names (such as [builtin]) to routers, possibly including new ones created for the application. There are a few basic routers in {{:../BantorraResolvers/index.html}BantorraResolvers} and {!module:Router} defines what a router is.
*)

(** {1 Format of Anchors}

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

    If the [deps] field is missing, then the library has no dependencies. Each dependency is specified by its mount point ([mount_point]), the name of the router to find the imported library ([router]), and the argument to the router ([router_argument]). During the resolution, the entire JSON subtree under the field [router_argument] is passed to the router. See {!type:Router.argument} and {!val:Router.make}.

    The order of entries in [dep] does not matter because the dispatching is based on longest prefix match. If no match can be found, then it means the unit path refers to a local unit. The same library can be mounted at multiple points. However, to keep the resolution unambiguous, there cannot be two libraries mounted at the same point. Here is an example demonstrating the longest prefix match:
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

    The unit path [world.orntorra] will be routed to the unit [orntorra] within the [world] library, pending further resolution (as the [world] library might further mount other libraries), while the unit path [world.bantorra.shisho] will be routed to [shisho] in the library corresponding to [https://github.com/RedPRL/bantorra], not the unit [bantorra.shisho] in the [world] library.

    If some library is mounted at [world.towitorra], then the original unit with the path [world.towitorra] or a path with the prefix [world.towitorra] is no longer accessible. Moreover, [world.towitorra] cannot point to any unit after the mounting because no unit can be associated with the empty path (the root), and [world.towitorra] means the empty path (the root) in the mounted library, which cannot refer to any unit.
*)

(** {1 Main Modules} *)

module Manager = Manager
(** Library managers. *)

module Router = Router
(** The type of routers. *)

(** {1 Helper Modules} *)

module Errors = Errors
(** Error reporting functions *)
