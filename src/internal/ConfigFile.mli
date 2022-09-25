val read : version:string -> FilePath.t -> (Marshal.value, Marshal.value) Hashtbl.t

val write : version:string -> FilePath.t -> (Marshal.value, Marshal.value) Hashtbl.t -> unit
