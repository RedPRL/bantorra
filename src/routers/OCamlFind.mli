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

val router : package_name:string -> dict:(string * string) list -> (Bantorra.Router.t, [> `InvalidRouter of string]) result
(** [router ~package_name ~dict] constructs a router based on the package directory given by {{:http://projects.camlcity.org/projects/findlib.html}findlib} and the mapping [dict]. All paths are normalized and turned into absolute paths with respect to the package directory. *)
