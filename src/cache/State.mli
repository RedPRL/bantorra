open Basis

type t

val init : unit -> t
val deserialize : Marshal.t -> t
val serialize : t -> Marshal.t

val update_atime : t -> key:string -> unit
