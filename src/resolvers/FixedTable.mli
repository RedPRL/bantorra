
(** A fixed-table resolver contains a fixed table from library names to paths to library roots. *)

(**
   {1 Argument Format}

   The resolver accepts simple JSON strings as library names.
*)

(**
    {1 Builder}
*)

type filepath = string

val resolver : dict:(string * filepath) list -> Bantorra.Resolver.t
(** [resolver ~dict] construct a resolver based on the mapping [dict]. All paths in [dict] will be normalized and turned into absolute paths with respect to the current working directory using {!val:BantorraBasis.File.normalize_dir}. *)
