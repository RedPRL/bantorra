(** A fixed-table router contains a fixed table from library names to paths to library roots. *)

(**
   {1 Argument Format}

   The router accepts simple JSON strings as library names.
*)

(**
    {1 Builder}
*)

val router : dict:(string * BantorraBasis.File.filepath) list ->
  (Bantorra.Router.t, [> `InvalidRouter of string]) result
(** [router ~dict] construct a router based on the mapping [dict]. All paths in [dict] will be normalized and turned into absolute paths with respect to the current working directory using {!val:BantorraBasis.File.normalize_dir}. *)
