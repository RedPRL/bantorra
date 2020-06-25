val (/) : string -> string -> string
val join : string list -> string
val writefile : string -> string -> unit
val writefile_noerr : string -> string -> unit
val readfile : string -> string
val ensure_dir : string -> unit
val protect_cwd : (string -> 'a) -> 'a
val normalize_dir : string -> string
val is_existing_and_regular : string -> bool
val locate_anchor : anchor:string -> string -> string * string list
val locate_anchor_ : anchor:string -> string -> string
