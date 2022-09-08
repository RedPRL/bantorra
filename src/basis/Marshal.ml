module E = Error

let destruct enc json =
  try
    Json_encoding.destruct enc json
  with e ->
    E.fatalf `JSONFormat "%a" (Json_encoding.print_error ?print_unknown:None) e

let construct enc data =
  try
    Json_encoding.construct enc data
  with e ->
    E.fatalf `JSONFormat "%a" (Json_encoding.print_error ?print_unknown:None) e

let parse s =
  try Ezjsonm.value_from_string s with
  | Ezjsonm.Parse_error (_, msg) ->
    E.fatalf `JSONFormat "%s" msg

let read enc path =
  File.read path |> parse |> destruct enc

let serialize ?(minify=true) enc data =
  data |> construct enc |> Ezjsonm.value_to_string ~minify

let write ?(minify=false) enc path data =
  data |> serialize ~minify enc |> File.write path
