(** {1 Types} *)

type param = Marshal.value
(** The type of parameters to routers. *)

type t = param -> FilePath.t
(** The type of library routers. *)

type pipe = param -> param

type table = (Marshal.value, Marshal.value) Hashtbl.t

(** {1 Algebraic Effects} *)

val get_starting_dir : unit -> FilePath.t option

val run : ?starting_dir:FilePath.t -> (unit -> 'a) -> 'a

(** {1 Built-in Routers and Utility Functions} *)

(** {2 Combinators} *)

val dispatch : (string -> t option) -> t
(** [dispatch lookup] accepts JSON [[name, arg]] and runs the router [lookup name] with [arg] *)

val rewrite : ?recursively:bool -> ?err_on_missing:bool -> (Marshal.value -> Marshal.value option) -> pipe
(** [rewrite lookup] rewrites the JSON parameter [param] to [param'] if [lookup param] is [Some param'].
    Otherwise, if [lookup param] is [None], the [param] is returned unchanged. *)

val fix : ?hop_limit:int -> (t -> t) -> t
(** [fix f] gives the fixed point of [f]. *)

(** {2 Direct Routers} *)

val local : ?relative_to:FilePath.t -> expanding_tilde:bool -> t
(** [local] accepts a JSON string [path] and return the [path] as a file path directly. *)

(** {2 Git} *)

val git : crate:FilePath.t -> t
(** [git ~crate] accepts JSON parameters in one of the following formats:

    {v
{ "url": "git@github.com:RedPRL/bantorra.git" }
    v}
    {v
{
  "url": "git@github.com:RedPRL/bantorra.git",
  "ref": "main"
}
    v}
    {v
{
  "url": "git@github.com:RedPRL/bantorra.git",
  "path": "src/library/"
}
    v}
    {v
{
  "url": "git@github.com:RedPRL/bantorra.git",
  "ref": "main",
  "path": "src/library/"
}
    v}
    The [ref] field can be a commit hash (object name), a branch name, a tag name, or essentially anything accepted by [git fetch]. (The older [git] before year 2015 would not accept commit IDs, but please upgrade it already.) The [path] field is the relative path pointing to the root of the library. If the [path] field is missing, then the tool assumes the library is at the root of the repository. If the [ref] field is missing, then ["HEAD"] is used, which points to the tip of the default branch in the remote repository.

    Different URLs pointing to the "same" git repository are treated as different repositories. Therefore, [git@github.com:RedPRL/bantorra.git] and [https://github.com/RedPRL/bantorra.git] are treated as two distinct git repositories. For the same repository, the commits in use must be identical during the program execution; one can use different branch names or tag names, but they must point to the same commit. The resolution would fail if there is an attempt to use different commits of the same repository.
*)

(** {2 Configuration Files} *)

(**
   Format of the configuration files:

   {v
{
    "format": "1.0.0",
    "rewrite":
      [ ["stdlib", ""]
      ]
}
    v}


*)


val read_config : version:string -> FilePath.t -> table
(** [read_config ~version path] reads the configuration file at [path] and parse it as a rewrite table. *)

val read_config_url : version:string -> string -> table

val write_config : version:string -> FilePath.t -> table -> unit
(** [write_config ~version path table] writes table to the file at [path]. *)
