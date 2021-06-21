(** Here are some examples of library routers. *)

module Direct = Direct

module FixedTable = FixedTable
(** Resolver based on a fixed table of libraries. *)

module Git = Git

module OCamlFind = OCamlFind
(** Resolver based on {{:http://projects.camlcity.org/projects/findlib.html}findlib}. *)

module UserConfig = UserConfig
(** Resolver based on per-user configurations. *)

module Waypoint = Waypoint
(** Resolver based on local waypoints. *)
