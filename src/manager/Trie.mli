open BantorraBasis

type +!'a t

val empty : 'a t
val singleton : UnitPath.t -> 'a -> 'a t
val add : UnitPath.t -> 'a -> 'a t -> 'a t
val find : UnitPath.t -> 'a t -> ('a * UnitPath.t) option
val iter_values : ('a -> unit) -> 'a t -> unit
