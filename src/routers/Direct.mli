(** A router that directly accepts the library root. *)

(**
   {1 Argument Format}

   The router accepts a string as an absolute path or a path relative to the library root.
*)


(**
    {1 Builder}
*)

val router : Bantorra.Router.t
