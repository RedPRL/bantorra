(** A router that uses {{:http://projects.camlcity.org/projects/findlib.html}findlib} to locate libraries. *)

(**
   This is a router similar to the fixed-table router {!module:FixedTable} except that each path is relative the package directory given by the OCaml library {{:http://projects.camlcity.org/projects/findlib.html}findlib}. The package directory is used by the [ocamlfind] tool as part of the standard OCaml toolchain.
*)

(**
   {1 Argument Format}

   The router accepts JSON strings as library names.
*)

(**
   {1 Builder}
*)

val get_package_dir : string -> BantorraBasis.FilePath.t
