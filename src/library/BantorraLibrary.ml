(**
   {1 Introduction}

   A library in the Bantorra framework is the collection of all units under some directory in the file system. Its root directory is marked by the existence of special files (called {e anchors}). An anchor not only labels the root directory for local unit path resolution, it also specifies a list of libraries the current library depends on.

   For example, an anchor can look like this
   {v
format: "1.0.0"
deps:
  - mount_point: [lib, num]
    resolver: builtin
    res_args: number
    v}
   The above anchor file mounts the library [number] at [lib.num] via the [builtin] resolver. We need to find the roots of imported libraries, which is exactly what a library manager will do. It is thus not recommended to use the API here directly.

   {1 Modules}
*)

(** This library defines user libraries managed by the bantorra framework. *)

module Library = Library
(** User libraries. *)

module Anchor = Anchor
(** Anchors of user libraries. *)
