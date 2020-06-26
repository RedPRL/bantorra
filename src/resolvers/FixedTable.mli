
(** {1 Introduction}

    A fixed-table resolver contains a fixed table from library names to paths to library roots.

    The resolver argument format is
    {[
      `String name
    ]}
    or, in terms of YAML, a simple string.

    {1 The Builder}
*)

val resolver : dict:(string * string) list -> Bantorra.Resolver.t
(** [resolver ~dict] construct a resolver based on the mapping [dict]. All paths in [dict] will be normalized and turned into absolute paths using {!val:BantorraBasis.File.normalize_dir}. *)
