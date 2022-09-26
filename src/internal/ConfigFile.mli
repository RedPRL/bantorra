val parse : version:string -> string -> (Marshal.value, Marshal.value) Hashtbl.t

val read : version:string -> FilePath.t -> (Marshal.value, Marshal.value) Hashtbl.t

val get_web : version:string -> string -> (Marshal.value, Marshal.value) Hashtbl.t

val write : version:string -> FilePath.t -> (Marshal.value, Marshal.value) Hashtbl.t -> unit
