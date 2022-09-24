open BantorraBasis
open Bantorra

val dispatch : (string -> Router.t option) -> Router.t
(** [dispatch lookup] accepts JSON [[name, arg]] and runs the router [lookup name] with [arg] *)

val fix : ?hop_limit:int -> (Router.t -> Router.t) -> Router.t
(** [fix f] gives the fixed point of [f]. *)

val git : crate:FilePath.t -> Router.t
(** [git ~crate] accepts JSON [] and return the [path] directly. *)

val local : ?relative_to:FilePath.t -> ?expanding_tilde:bool -> Router.t
(** [local] accepts JSON [path] and return the [path] directly. *)

val rewrite : ?recursively:bool -> (Marshal.value -> Marshal.value option) -> Router.pipe
(** [rewrite lookup] rewrites the JSON parameter [param] to [lookup param]. *)

type table = (Marshal.value, Marshal.value) Hashtbl.t

val get_package_dir : string -> FilePath.t

val read_config : version:string -> FilePath.t -> table
(** [read_config ~version path] reads the configuration file at [path] and parse it as a rewrite table. *)

val write_config : version:string -> FilePath.t -> table -> unit
(** [write_config ~version path table] writes table to the file at [path]. *)
