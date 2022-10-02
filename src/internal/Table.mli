type t = (Marshal.value, Marshal.value) Hashtbl.t

val lookup : t -> Marshal.value -> Marshal.value option

val parse : version:string -> string -> t

val read : version:string -> FilePath.t -> t

val get_web : version:string -> string -> t

val write : version:string -> FilePath.t -> t -> unit
