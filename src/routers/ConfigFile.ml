open BantorraBasis
module E = Error

type t = (Marshal.value, Marshal.value) Hashtbl.t

module Json =
struct
  module J = Json_encoding
  let replaced = J.any_ezjson_value
  let replacement = J.any_ezjson_value
  let entry = J.tup2 replaced replacement
  let table = J.dft ~title:"replace" ~description:"replacement table for routing parameters" "rewrite" (J.list entry) []
  let version v = J.req "version" (J.constant v)
  let config v = J.obj2 (version v) table
end

let read ~version path : t =
  let (), l = Marshal.read (Json.config version) path in
  let table = Hashtbl.create 0 in
  l |> List.iter (fun (key, value) ->
      let key = Marshal.normalize key in
      if Hashtbl.mem table key then
        E.fatalf `InvalidRouter "Duplicate rewrite key %s" (Marshal.serialize Json_encoding.any_ezjson_value key)
      else
        Hashtbl.replace table key value
    );
  table

let write ~version path table =
  let l = List.of_seq @@ Hashtbl.to_seq table in
  Marshal.write ~minify:false (Json.config version) path ((), l)
