open Basis.YamlIO

type t = (string, float) Hashtbl.t

let version = "1.0.0"

let init () : t = Hashtbl.create 10

let access_of_yaml =
  function
  | filename, `Float time -> filename, time
  | _ -> raise IllFormed

let of_yaml : yaml -> t =
  function
  | `O ["format", `String v; "atime", `O logs] when v = version ->
    Hashtbl.of_seq @@ Seq.map access_of_yaml @@ List.to_seq logs
  | _ -> raise IllFormed

let yaml_of_access (filename, time) =
  filename, `Float time

let to_yaml s =
  let logs = List.of_seq @@ Seq.map yaml_of_access @@ Hashtbl.to_seq s in
  `O ["format", `String version; "atime", `O logs]

let update_atime s ~key =
  Hashtbl.replace s key @@ Unix.time ();
