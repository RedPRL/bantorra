(** Absolute file paths *)

type t
val equal : t -> t -> bool
val compare : t -> t -> int
val is_root : t -> bool
val is_dir_path : t -> bool
val to_dir_path : t -> t
val parent : t -> t
val basename : t -> string
val has_ext : string -> t -> bool
val add_ext : string -> t -> t
val rem_ext : t -> t
val add_unit_seg : t -> string -> t
val append_unit : t -> UnitPath.t -> t
val of_fpath : ?relative_to:t -> ?expanding_tilde:t -> Fpath.t -> t
val to_fpath : t -> Fpath.t
val of_string : ?relative_to:t -> ?expanding_tilde:t -> string -> t
val to_string : t -> string
val pp : Format.formatter -> t -> unit
