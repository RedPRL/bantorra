open BantorraBasis

(** {1 Types} *)

type t
(** The type of anchors. *)

(** {1 Anchor I/O} *)

val read : version:string -> File.path -> t
(** [read path] read the content of an anchor file. *)

(** {1 Accessors} *)

val iter_routes : (Router.route -> unit) -> t -> unit

val dispatch_path : t -> UnitPath.t -> (Router.route * UnitPath.t) option
(** [dispatch_path a p] routes the unit path [p] to [Some (ref, p')] if it points to a unit in another library referenced by [ref] and [p'], or [None] if it is a local unit path. The dispatching is done by longest prefix match. *)

val path_is_local : t -> UnitPath.t -> bool
