(** Error reporting functions *)

(** {1 System Errors} *)

val error_system_msg : src:string -> string -> ('a, [> `SystemError of string ]) Stdlib.result
val error_system_msgf : src:string -> ('a, Stdlib.Format.formatter, unit, ('b, [> `SystemError of string ]) Stdlib.result) Stdlib.format4 -> 'a
val append_error_system_msg : src:string -> earlier:string -> string -> ('a, [> `SystemError of string ]) Stdlib.result
val append_error_system_msgf : src:string -> earlier:string -> ('a, Stdlib.Format.formatter, unit, ('b, [> `SystemError of string ]) Stdlib.result) Stdlib.format4 -> 'a

(** {1 Anchor Not Found} *)

val error_anchor_not_found_msg : src:string -> string -> ('a, [> `AnchorNotFound of string ]) Stdlib.result
val error_anchor_not_found_msgf : src:string -> ('a, Stdlib.Format.formatter, unit, ('b, [> `AnchorNotFound of string ]) Stdlib.result) Stdlib.format4 -> 'a
val append_error_anchor_not_found_msg : src:string -> earlier:string -> string -> ('a, [> `AnchorNotFound of string ]) Stdlib.result
val append_error_anchor_not_found_msgf : src:string -> earlier:string -> ('a, Stdlib.Format.formatter, unit, ('b, [> `AnchorNotFound of string ]) Stdlib.result) Stdlib.format4 -> 'a

(** {1 Format Errors} *)

val error_format_msg : src:string -> string -> ('a, [> `FormatError of string ]) Stdlib.result
val error_format_msgf : src:string -> ('a, Stdlib.Format.formatter, unit, ('b, [> `FormatError of string ]) Stdlib.result) Stdlib.format4 -> 'a
val append_error_format_msg : src:string -> earlier:string -> string -> ('a, [> `FormatError of string ]) Stdlib.result
val append_error_format_msgf : src:string -> earlier:string -> ('a, Stdlib.Format.formatter, unit, ('b, [> `FormatError of string ]) Stdlib.result) Stdlib.format4 -> 'a
