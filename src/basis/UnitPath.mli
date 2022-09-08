type t
val equal : t -> t -> bool
val compare : t -> t -> int
val root : t
val is_root : t -> bool
val is_seg : string -> bool
val assert_seg : string -> unit
val of_seg : string -> t
val add_seg : t -> string -> t
val prepend_seg : string -> t -> t
val to_list : t -> string list
val of_list : string list -> t
val of_string : string -> t
val to_string : t -> string
val pp : Format.formatter -> t -> unit

(**/**)

val unsafe_of_list : string list -> t
