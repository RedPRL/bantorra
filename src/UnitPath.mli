(** Unit paths. *)

(** {1 Type} *)

type t

(** {1 Comparison} *)

val equal : t -> t -> bool
val compare : t -> t -> int

(** {1 Root} *)

val root : t
val is_root : t -> bool

(** {1 Segments} *)

val is_seg : string -> bool
(** [is_seg d] checks whether [d] is a valid segment, which means [d] is a valid directory name and is not [.] or [..]. *)

val of_seg : string -> t
val add_seg : t -> string -> t
val prepend_seg : string -> t -> t

(** {1 Conversion to/from lists} *)

val to_list : t -> string list
val of_list : string list -> t

(** {1 Conversion to/from strings} *)

val of_string : ?allow_ending_slash:bool -> ?allow_extra_dots:bool -> string -> t
val to_string : t -> string

(** {1 Pretty printer} *)

val pp : Format.formatter -> t -> unit

(**/**)

val unsafe_of_list : string list -> t
