(** A relative-path resolver contains a fixed table from library names to paths to library roots. *)

(**
   {1 Argument Format}

   The resolver accepts an array of strings, representing a relative path to the library root.
   For example, assuming that the resolver name "at" 


    {v
{
  "format": "1.0.0",
  "deps": [
    {
      "mount_point": ["path", "to", "lib1"],
      "resolver": "resolver1",
      "resolver_argument": ...
    },
    {
      "mount_point": ["path", "to", "lib2"],
      "resolver": "resolver2",
      "resolver_argument": ...
    }
  ]
}
    v}
*)


(**
    {1 Builder}
*)

val resolver : Bantorra.Resolver.t
(** [resolver]  All paths in [dict] will be normalized and turned into absolute paths with respect to the current working directory using {!val:BantorraBasis.File.normalize_dir}. *)
