open Basis

type t = (string, float) Hashtbl.t

let version = "1.0.0"

let init () : t = Hashtbl.create 10

let to_access =
  function
  | filename, `Float time -> filename, time
  | _ -> raise Marshal.IllFormed

let deserialize : Marshal.t -> t =
  function
  | `O ["format", `String v; "atime", `O logs] when v = version ->
    Hashtbl.of_seq @@ Seq.map to_access @@ List.to_seq logs
  | _ -> raise Marshal.IllFormed

let of_access (filename, time) =
  filename, `Float time

let serialize s =
  let logs = List.of_seq @@ Seq.map of_access @@ Hashtbl.to_seq s in
  `O ["format", `String version; "atime", `O logs]

let update_atime s ~key =
  Hashtbl.replace s key @@ Unix.time ();
