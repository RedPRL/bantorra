module Syntax :
sig
  val ret : 'a -> ('a, 'e) result
  val error : 'e -> ('a, 'e) result
  val (>>=) : ('a, 'e) result -> ('a -> ('c, 'e) result) -> ('c, 'e) result
  val (<$>) : ('a -> 'b) -> ('a, 'e) result -> ('b, 'e) result
  val (let*) : ('a, 'e) result -> ('a -> ('c, 'e) result) -> ('c, 'e) result
  val (and*) : ('a, 'e) result -> ('b, 'e) result -> ('a * 'b, 'e) result
  val (let+) : ('a, 'e) result -> ('a -> 'b) -> ('b, 'e) result
  val (and+) : ('a, 'e) result -> ('b, 'e) result -> ('a * 'b, 'e) result
end

val ignore_error : (unit, 'e) result -> unit
val map : ('a -> ('b, 'e) result) -> 'a list -> ('b list, 'e) result
val iter : ('a -> (unit, 'b) result) -> 'a list -> (unit, 'b) result
val iter_seq : ('a -> (unit, 'b) result) -> 'a Seq.t -> (unit, 'b) result
