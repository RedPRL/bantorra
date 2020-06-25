open BantorraBasis

type t
(** The type of cache stores. *)

val init : unit -> t
(** Initialize the state. *)

val update_atime : t -> key:string -> unit
(** Update the access time of a key. This is for the (unimplemented) LRU
    or other cache management policies. We need to keep our own records
    because access times are probably disabled on modern computers
    (for good reasons). *)

val serialize : t -> Marshal.t
(** Serialize a state. *)

val deserialize : Marshal.t -> t
(** Deserialize a state. *)
