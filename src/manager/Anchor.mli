open BantorraBasis

(** {1 Types} *)

type t
(** The type of anchors. *)

type path = string list
(** The type of unit paths. *)

(** {1 Anchor I/O} *)

val read : File.filepath -> (t, [> `FormatError of string | `SystemError of string ]) result
(** [read path] read the content of an anchor file. *)

(** {1 Accessors} *)

val iter_routes : (router:string -> router_argument:Marshal.value -> (unit, 'e) result) -> t -> (unit, 'e) result

val dispatch_path : t -> path -> (string * Marshal.value * path) option
(** [dispatch_path a p] routes the unit path [p] to [Some (ref, p')] if it points to a unit in another library referenced by [ref] and [p'], or [None] if it is a local unit path. The dispatching is done by longest prefix match. *)

val path_is_local : t -> path -> bool
