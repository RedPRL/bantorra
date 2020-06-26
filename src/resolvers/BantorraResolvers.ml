(**
   {1 Introduction}

   Here are some examples of library resolvers.

   {1 Resolvers}
*)

module FixedTable = FixedTable
(** Resolver based on a fixed table of libraries. *)

module OCamlFind = OCamlFind
(** Resolver based on the [ocamlfind] tool. *)

module Waypoint = Waypoint
(** Resolver based on local waypoints. *)

module UserConfig = UserConfig
(** Resolver based on per-user configurations. *)