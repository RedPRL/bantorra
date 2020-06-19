module J = Ezjsonm
module G = Ezgzip

open Util

type json_value = J.value
type json = J.t

let write_json path value =
  writefile path @@ G.compress @@ J.to_string ~minify:true value

let read_json path =
  match Result.map J.from_string @@ G.decompress @@ readfile path with
  | Ok json -> json
  | Error _ -> raise Not_found
  | exception _ -> raise Not_found

module State =
struct
  exception IllFormed

  type t = (string, float) Hashtbl.t

  let version = "1.0.0"

  let init () : t = Hashtbl.create 10

  let access_of_json =
    function
    | filename, `Float time -> filename, time
    | _ -> raise IllFormed

  let of_json : json -> t =
    function
    | `O ["version", `String v; "atime", `O logs] when v = version ->
      Hashtbl.of_seq @@ Seq.map access_of_json @@ List.to_seq logs
    | _ -> raise IllFormed

  let json_of_access (filename, time) =
    filename, `Float time

  let to_json s =
    let logs = List.of_seq @@ Seq.map json_of_access @@ Hashtbl.to_seq s in
    `O ["version", `String version; "atime", `O logs]
end

module Database =
struct
  type t =
    { root: string
    ; state: State.t
    }

  let read_state ~root =
    try State.of_json @@ read_json (root/"state") with _ -> State.init ()

  let init ~root =
    ensure_dir (root/"data");
    {root; state = read_state ~root}

  let save {root; state} =
    write_json (root/"state") @@ State.to_json state

  let replace {root; state} ~key ~value =
    let key = Digest.to_hex @@ Digest.string @@ J.value_to_string ~minify:true key
    and value = G.compress @@ J.to_string ~minify:true value in
    Hashtbl.replace state key @@ Unix.time ();
    writefile (root/"data"/key) value;
    Digest.to_hex @@ Digest.string value

  let find_opt {root; state} ~key ~digest =
    let key = Digest.to_hex @@ Digest.string @@ J.value_to_string ~minify:true key in
    match
      let value = readfile (root/"data"/key) in
      begin
        match digest with
        | Some d -> if Digest.string value <> d then raise Not_found
        | None -> ()
      end;
      Result.map J.from_string @@ G.decompress value
    with
    | Ok json -> Hashtbl.replace state key @@ Unix.time (); Some json
    | Error _ -> None
    | exception _ -> None
end
