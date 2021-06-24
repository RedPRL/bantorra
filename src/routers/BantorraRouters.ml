(** Here are some examples of library routers. *)

module Direct = Direct
(** A router that directly takes the library root. *)

module FixedTable = FixedTable
(** A router uses a fixed mapping table. *)

module Git = Git
(** A router that downloads git repositories. *)

module OCamlFind = OCamlFind
(** A router using {{:http://projects.camlcity.org/projects/findlib.html}findlib}. *)

module UserConfig = UserConfig
(** A router that uses per-user configuration files. *)

module Waypoint = Waypoint
(** A router that traverse the file system using landmark files. *)
