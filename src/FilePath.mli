(** Absolute file paths. *)

(** The API mimics the [fpath] library, but with optional arguments [relative_to] and [expanding_tilde]
    to turn relative paths into absolute ones when needed.

    No functions in this module access the actual file systems. *)

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
(** Append a unit segment to a file path. *)

val append_unit : t -> UnitPath.t -> t
(** Append a unit path to a file path. *)

val of_fpath : ?relative_to:t -> ?expanding_tilde:t -> Fpath.t -> t
val to_fpath : t -> Fpath.t
val of_string : ?relative_to:t -> ?expanding_tilde:t -> string -> t
val to_string : t -> string
val pp : relative_to:t -> Format.formatter -> t -> unit

val pp_abs : Format.formatter -> t -> unit
(** An alias of [Fpath.pp]. *)
