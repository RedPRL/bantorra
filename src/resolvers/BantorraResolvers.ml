(**
   {1 A Collection of Simple Resolvers}

   These are some examples of library resolvers.
*)

module FixedTable = FixedTable
(* Resolver based on a fixed table of absolute paths. *)

module OCamlFind = OCamlFind
(* Resolver based on a fixed table of paths relative to the package directory given by the ocamlfind tool. *)

module Waypoint = Waypoint
(* Resolver based on local waypoints. *)

module UserConfig = UserConfig
(* Resolver based on per-user configurations. *)
