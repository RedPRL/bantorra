include module type of BantorraBasis.Errors

(** {1 Unit Not Found} *)

val error_unit_not_found_msg : src:string -> string -> ('a, [> `UnitNotFound of string ]) Stdlib.result
val error_unit_not_found_msgf : src:string -> ('a, Stdlib.Format.formatter, unit, ('b, [> `UnitNotFound of string ]) Stdlib.result) Stdlib.format4 -> 'a
val append_error_unit_not_found_msg : src:string -> earlier:string -> string -> ('a, [> `UnitNotFound of string ]) Stdlib.result
val append_error_unit_not_found_msgf : src:string -> earlier:string -> ('a, Stdlib.Format.formatter, unit, ('b, [> `UnitNotFound of string ]) Stdlib.result) Stdlib.format4 -> 'a
val open_error_unit_not_found : ('a, [< `UnitNotFound of 'b ]) Stdlib.result -> ('a, [> `UnitNotFound of 'b ]) Stdlib.result

(** {1 Invalid Libraries} *)

val error_invalid_library_msg : src:string -> string -> ('a, [> `InvalidLibrary of string ]) Stdlib.result
val error_invalid_library_msgf : src:string -> ('a, Stdlib.Format.formatter, unit, ('b, [> `InvalidLibrary of string ]) Stdlib.result) Stdlib.format4 -> 'a
val append_error_invalid_library_msg : src:string -> earlier:string -> string -> ('a, [> `InvalidLibrary of string ]) Stdlib.result
val append_error_invalid_library_msgf : src:string -> earlier:string -> ('a, Stdlib.Format.formatter, unit, ('b, [> `InvalidLibrary of string ]) Stdlib.result) Stdlib.format4 -> 'a
val open_error_invalid_library : ('a, [< `InvalidLibrary of 'b ]) Stdlib.result -> ('a, [> `InvalidLibrary of 'b ]) Stdlib.result

(** {1 Invalid Routers} *)

val error_invalid_router_msg : src:string -> string -> ('a, [> `InvalidRouter of string ]) Stdlib.result
val error_invalid_router_msgf : src:string -> ('a, Stdlib.Format.formatter, unit, ('b, [> `InvalidRouter of string ]) Stdlib.result) Stdlib.format4 -> 'a
val append_error_invalid_router_msg : src:string -> earlier:string -> string -> ('a, [> `InvalidRouter of string ]) Stdlib.result
val append_error_invalid_router_msgf : src:string -> earlier:string -> ('a, Stdlib.Format.formatter, unit, ('b, [> `InvalidRouter of string ]) Stdlib.result) Stdlib.format4 -> 'a
val open_error_invalid_router : ('a, [< `InvalidRouter of 'b ]) Stdlib.result -> ('a, [> `InvalidRouter of 'b ]) Stdlib.result
