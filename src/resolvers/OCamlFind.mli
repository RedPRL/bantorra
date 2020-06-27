
(** {1 Introduction}

    This is a resolver similar to the fixed-table resolver {!module:FixedTable} except that each path is relative the package directory given by the [ocamlfind] tool.

    The resolver argument format is
    {[
      `String name
    ]}
    or, in terms of YAML, a simple string.

    {1 The Builder}
*)

val resolver : package_name:string -> dict:(string * string) list -> Bantorra.Resolver.t
(** [resolver ~package_name ~dict] constructs a resolver based on the package directory given by the [ocamlfind] tool and the mapping [dict]. All paths are normalized and turned into absolute paths with respect to the current working directory using {!val:BantorraBasis.File.normalize_dir}. *)
