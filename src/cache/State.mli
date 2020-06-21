open Basis.JSON

type t

val init : unit -> t
val of_json : json -> t
val to_json : t -> json

val update_atime : t -> key:string -> unit
