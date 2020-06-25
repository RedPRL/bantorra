(**
   {1 Introduction}

   A library manager in the Bantorra framework maintains a tree of units that can be accessed via unit paths from the root. The framework maps each unit path to the underlying file path through a flexible resolution process that supports many existing mechanisms found in other library management systems. It also supports caching of compiled results.

   In the simplest case, there is a one-to-one correspondence between units and files under a directory: the unit path [a.b.c] corresponds to the file [a/b/c.suffix] where [suffix] is specified by the application. The library root directory is marked by special files with the special name specified by the application. For example, the [dune] file identifies the root of an OCaml library within the dune framework. These files are called {e anchors} in the Bantorra framework, each identifies a collection of units that forms a {e library}.

   To access the units in other libraries, an anchor can {e mount} a library in the tree, just like how partitions are mounted in POSIX-compliant systems. Here is a sample anchor file:
   {v
format: "1.0.0"
deps:
  - mount_point: [lib, num]
    resolver: builtin
    res_args: number
    v}
   The above anchor file mounts the built-in library [number] at [lib.num]. With this, the unit path [lib.num.types], for example, will be understood as the unit path [types] within the built-in library [number]. The [builtin] resolver is responsible for locating the root of the [number] library so that further resolution can continue. The resolution process is recursive because the depended library may depend on yet another library.

   The application can specify an arbitrary mapping from labels such as [builtin] to resolvers, possibly including new ones created for the application. There are a few basic resolvers in {{:../BantorraResolvers/index.html}BantorraResolvers}.

   {1 Modules}
*)

module Manager = Manager
(** Library managers: the entry points. *)

module Resolver = Resolver
(** Types of library resolvers. *)
