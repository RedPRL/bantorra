(**
   A Bantorra library is a virtual tree of units that can be accessed via unit paths from the root. The framework maps each unit path to the underlying file path via a flexible resolution process.

   In the simplest case, there is a one-to-one correspondence between units and files under a specific directory: the unit path [a.b.c] corresponds to the file [a/b/c.suffix] where the extension [.suffix] is specified by the application. The root directory is marked by the existence of a special file with a name specified by the application. For example, the existence of the [dune] file means there is an OCaml library in the eyes of the [dune] building tool. These files are called {e anchors} in the Bantorra framework, each marking the root of a collection of units that forms a {e library}.

   To access the units outside the current library, an anchor may {e mount} a library in the tree, in a way similar to how partitions are mounted in POSIX-compliant systems. Here is a sample anchor file:
   {v
{
  "format": "1.0.0",
  "depends": [
    {
      "mount_point": ["lib", "num"],
      "router": "builtin",
      "router_argument": "number"
    }
  ]
}
    v}
   The above anchor file mounts the library [number] at [lib.num] via the [builtin] router. With this, the unit path [lib.num.types], for example, will be routed as the unit path [types] within the library [number]. The [builtin] router here is responsible for locating the root of this [number] library. The resolution is recursive because the depended library may depend on yet another library.

   The implementation of the [builtin] router is specified by the application. For example, the application could use a fixed table router to implement the [builtin] router. A few basic routers are provided in {{:../BantorraRouters/index.html}BantorraRouters}.

   A Bantorra library manager holds the mapping from router names (such as [builtin]) to their implimentations (such as the fixed table) and is responsible for loading libraries. The manager is the entry point of the Bantorra framework---one should always start with a library manager and use it to load libraries. Here is an example:
   {[
     open Bantorra
     open BantorraRouters

     (* Create a fixed table router, ignoring errors. *)
     let builtin = Result.get_ok @@ FixedTable.router ~dict:["number", "../lib/number"]

     (** Get a library manager (ignoring error handling). *)
     let manager = Result.get_ok @@ Manager.init ~anchor:"lib" ~routers:["builtin", builtin]

     (** Load the library where the current directory belongs. *)
     let lib_cwd, _ = Result.get_ok @@ Manager.load_library_from_cwd manager

     (** Load a library using the [builtin] router. *)
     let lib_number = Result.get_ok @@
       Manager.load_library_from_route manager
         ~starting_dir:(Sys.getcwd ())
         ~router:"builtin"
         ~router_argument:(`String "number")

     (** Directly load the library from its root without using any routing.
         (The manager will return the same library.) *)
     let lib_number2 = Result.get_ok @@
       Manager.load_library_from_root manager "../lib/number"

     (** Resolve a unit path and get its location in the file system. *)
     let _local_lib, _local_unitpath, _filepath = Result.get_ok @@
       Manager.resolve manager lib_number ["integer"; "relations"] ~suffix:".source"

     (** Resolve the same unit path but with a different suffix. *)
     let _local_lib, _local_unitpath, _filepath = Result.get_ok @@
       Manager.resolve manager lib_number ["integer"; "relations"] ~suffix:".compiled"

     (** Resolve another unit path and get its location in the file system.
         The result is the same as above because the library represented
         by [lib_number] is mounted at [lib.num]. *)
     let local_lib2, local_path2, filepath2 = Result.get_ok @@
       Manager.resolve manager lib_cwd ["lib"; "num"; "integer"; "relations"] ~suffix:".source"
   ]}

   As shown above, the application can specify an arbitrary mapping from router names (such as [builtin]) to routers, possibly including new ones created for the application. There are a few basic routers in {{:../BantorraResolvers/index.html}BantorraResolvers} and {!module:Router} defines what a router is.
*)

(** {1 Components} *)

module Manager = Manager
(** Library managers. *)

module Router = Router
(** The type of routers. *)

module Errors = Errors
(** Utility functions to report errors. *)
