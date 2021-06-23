
val error_msg : tag:(string -> ('a, 'b) result) -> src:string -> string -> ('a, 'b) result

val error_msgf : tag:(string -> ('a, 'b) result) -> src:string -> ('c, Format.formatter, unit, ('a, 'b) result) format4 -> 'c

val append_error_msg : tag:(string -> ('a, 'b) result) -> earlier:string -> src:string -> string -> ('a, 'b) result

val append_error_msgf : tag:(string -> ('a, 'b) result) -> earlier:string -> src:string -> ('c, Format.formatter, unit, ('a, 'b) result) format4 -> 'c

val pp_lines : Format.formatter -> string -> unit
