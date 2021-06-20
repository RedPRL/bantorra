module Hashtbl :
sig
  val of_unique_seq : ('a * 'b) Seq.t -> (('a, 'b) Hashtbl.t, [> `DuplicateKeys of 'a]) result
  (** This is similar to [Hashtbl.of_seq] except that it will abort when there are duplicate keys. *)
end
