val error_msg : tag:(string -> ('a, 'b) result) -> src:string -> string -> ('a, 'b) result
(** Turn an error message into an error. *)

val error_msgf : tag:(string -> ('a, 'b) result) -> src:string -> ('c, Format.formatter, unit, ('a, 'b) result) format4 -> 'c
(** Format an error message. *)

val append_error_msg : tag:(string -> ('a, 'b) result) -> earlier:string -> src:string -> string -> ('a, 'b) result
(** Append an error message to an earlier error. *)

val append_error_msgf : tag:(string -> ('a, 'b) result) -> earlier:string -> src:string -> ('c, Format.formatter, unit, ('a, 'b) result) format4 -> 'c
(** Format and append an error message to an earlier error. *)

val pp_lines : Format.formatter -> string -> unit
(** Pretty printer that hints newlines for ['\n']. *)
