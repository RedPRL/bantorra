open BantorraBasis

(** {1 Types} *)

type route = Json_repr.ezjsonm
(** The type of arguments to routers. *)

type t = ?hop_limit:int -> lib_root:File.path -> route -> File.path
(** The type of library routers. *)

(** {1 Combinators} *)

val fix : (t -> t) -> t
