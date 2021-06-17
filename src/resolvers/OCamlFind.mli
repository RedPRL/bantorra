
(**
   This is a resolver similar to the fixed-table resolver {!module:FixedTable} except that each path is relative the package directory given by the OCaml library {{:http://projects.camlcity.org/projects/findlib.html}findlib}. The package directory is used by the [ocamlfind] tool as part of the standard OCaml toolchain.
*)

(**
   {1 Argument Format}

   The resolver accepts JSON strings as library names.
*)

(**
   {1 Builder}
*)

val resolver : package_name:string -> dict:(string * string) list -> Bantorra.Resolver.t
(** [resolver ~package_name ~dict] constructs a resolver based on the package directory given by {{:http://projects.camlcity.org/projects/findlib.html}findlib} and the mapping [dict]. All paths are normalized and turned into absolute paths with respect to the current working directory using {!val:BantorraBasis.File.normalize_dir}. *)
