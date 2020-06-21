open Basis.YamlIO

type t

val init : unit -> t
val of_yaml : yaml -> t
val to_yaml : t -> yaml

val update_atime : t -> key:string -> unit
