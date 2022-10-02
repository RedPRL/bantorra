module E = Error

type t = (Marshal.value, Marshal.value) Hashtbl.t

module Json =
struct
  module J = Json_encoding
  let format v = J.req ~title:"format version" ~description:"format version of the configuration file" "format" (J.constant v)
  let replaced = J.any_ezjson_value
  let replacement = J.any_ezjson_value
  let entry = J.tup2 replaced replacement
  let table = J.dft ~title:"replace" ~description:"replacement table for routing parameters" "rewrite" (J.list entry) []
  let config v = J.obj2 (format v) table
end

let parse ~version str : t =
  let (), l = Marshal.parse (Json.config version) str in
  let table = Hashtbl.create 0 in
  l |> List.iter (fun (key, value) ->
      let key = Marshal.normalize key in
      if Hashtbl.mem table key then
        E.fatalf `InvalidRouter "Duplicate rewrite key %s" (Marshal.to_string key)
      else
        Hashtbl.replace table key value
    );
  table

let lookup tbl param = Hashtbl.find_opt tbl (Marshal.normalize param)

let read ~version path : t =
  parse ~version @@ File.read path

let get_web ~version url : t =
  parse ~version @@ Web.get url

let write ~version path table =
  let l = List.of_seq @@ Hashtbl.to_seq table in
  Marshal.write ~minify:false (Json.config version) path ((), l)
