open File
open Yaml

type yaml = value

exception IllFormed

let digest_of_value v = v |> Yaml.to_string |> Result.get_ok |> Digest.string |> Digest.to_hex

let of_gzip z = try z |> Ezgzip.decompress |> Result.get_ok |> Yaml.of_string |> Result.get_ok with _ -> raise IllFormed
let to_gzip j = j |> Yaml.to_string |> Result.get_ok |> Ezgzip.compress
let write_gzip path j = writefile path @@ to_gzip j
let read_gzip path = of_gzip @@ readfile path

let of_plain p = try p |> Yaml.of_string |> Result.get_ok with _ -> raise IllFormed
let to_plain j = j |> Yaml.to_string |> Result.get_ok
let write_plain path j = writefile path @@ to_plain j
let read_plain path = of_plain @@ readfile path

let yaml_of_string s = `String s
let string_of_yaml =
  function
  | `String s -> s
  | _ -> raise IllFormed

let yaml_of_ostring =
  function
  | None -> `Null
  | Some s -> `String s

let ostring_of_yaml =
  function
  | `String str -> Some str
  | `Null -> None
  | _ -> raise IllFormed

let yaml_of_list yaml_of_item l =
  `A (List.map yaml_of_item l)
let list_of_yaml item_of_yaml =
  function
  | `A items -> List.map item_of_yaml items
  | _ -> raise IllFormed

let yaml_of_float f = `Float f
let float_of_yaml =
  function
  | `Float f -> f
  | _ -> raise IllFormed
