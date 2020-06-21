open File

type json_value = Ezjsonm.value
type json = Ezjsonm.t

exception IllFormed

let digest_of_value v = v |> Ezjsonm.value_to_string |> Digest.string |> Digest.to_hex

let of_gzip z = try z |> Ezgzip.decompress |> Result.get_ok |> Ezjsonm.from_string with _ -> raise IllFormed
let to_gzip j = j |> Ezjsonm.to_string ~minify:true |> Ezgzip.compress
let write_gzip path j = writefile path @@ to_gzip j
let read_gzip path = of_gzip @@ readfile path

let of_plain p = try p |> Ezjsonm.from_string with _ -> raise IllFormed
let to_plain j = j |> Ezjsonm.to_string ~minify:false
let write_plain path j = writefile path @@ to_plain j
let read_plain path = of_plain @@ readfile path

let json_of_string s = `String s
let string_of_json =
  function
  | `String str -> str
  | _ -> raise IllFormed

let json_of_ostring =
  function
  | None -> `Null
  | Some s -> `String s

let ostring_of_json =
  function
  | `String str -> Some str
  | `Null -> None
  | _ -> raise IllFormed

let json_of_list json_of_item l =
  `A (List.map json_of_item l)
let list_of_json item_of_json =
  function
  | `A items -> List.map item_of_json items
  | _ -> raise IllFormed

let json_of_float f = `Float f
let float_of_json =
  function
  | `Float f -> f
  | _ -> raise IllFormed
