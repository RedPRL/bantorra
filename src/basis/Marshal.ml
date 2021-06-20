open ResultMonad.Syntax
open File

type value = Ezjsonm.value

let format_error s = error @@ `FormatError s

let of_json p =
  try ret @@ Ezjsonm.value_from_string p with
  | Ezjsonm.Parse_error (_, s) -> error @@ `FormatError s
let read_json path = readfile path >>= of_json

let to_json ?(minify=true) j = Ezjsonm.value_to_string ~minify j
let write_json ?minify path j = writefile path @@ to_json ?minify j

let of_string s = `String s
let to_string : value -> (string, [> `FormatError of string]) result =
  function
  | `String s -> ret s
  | v -> format_error @@ to_json v

let of_ostring =
  function
  | None -> `Null
  | Some s -> `String s
let to_ostring =
  function
  | `String str -> ret @@ Some str
  | `Null -> ret None
  | v -> format_error @@ to_json v

let of_list of_item l =
  `A (List.map of_item l)
let to_list to_item =
  function
  | `A items -> ResultMonad.map to_item items
  | v -> format_error @@ to_json v

let of_olist of_item =
  function
  | None -> `Null
  | Some l -> of_list of_item l
let to_olist to_item =
  function
  | `A items ->
    let+ l = ResultMonad.map to_item items in Some l
  | `Null -> ret None
  | v -> format_error @@ to_json v

let of_float f = `Float f
let to_float =
  function
  | `Float f -> ret f
  | v -> format_error @@ to_json v

let dump v = Ezjsonm.value_to_string v
