open BantorraBasis

(** {1 Types} *)

type t
(** The type of cache stores. *)

(** {1 Initialization} *)

val init : unit -> t
(** Initialize the state. *)

val serialize : t -> Marshal.t
(** Serialize a state. *)

val deserialize : Marshal.t -> t
(** Deserialize a state. *)

(** {1 Accessors} *)

val update_atime : t -> key:string -> unit
(** Update the access time of a key. This is for the (unimplemented) LRU
    or other cache management policies. We need to keep our own records
    because access times are probably disabled on modern computers
    (for good reasons). *)
