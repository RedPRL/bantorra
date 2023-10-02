type value = Json_repr.ezjsonm

let rec find_duplicate_key =
  function
  | [] | [_] -> assert false
  | x1 :: x2 :: _ when String.equal (fst x1) (fst x2) -> fst x1
  | _ :: xs -> find_duplicate_key xs

let rec normalize : value -> value =
  function
  | `O pairs ->
    let pairs = List.map (fun (p, v) -> p, normalize v) pairs in
    let sorted_uniq_pairs = List.sort_uniq (fun (key1, _) (key2, _) -> String.compare key1 key2) pairs in
    if List.length pairs <> List.length sorted_uniq_pairs then
      let sorted_pairs = List.sort (fun (key1, _) (key2, _) -> String.compare key1 key2) pairs in
      Logger.fatalf `JSONFormat "Duplicate key: %s" (find_duplicate_key sorted_pairs)
    else
      `O sorted_uniq_pairs
  | `A elems -> `A (List.map normalize elems)
  | (`Bool _ | `Float _ | `String _ | `Null) as j -> j

let destruct enc json =
  try
    Json_encoding.destruct enc json
  with e ->
    Logger.fatalf `JSONFormat "%a" (Json_encoding.print_error ?print_unknown:None) e

let construct enc data =
  try
    Json_encoding.construct enc data
  with e ->
    Logger.fatalf `JSONFormat "%a" (Json_encoding.print_error ?print_unknown:None) e

let parse enc s =
  destruct enc @@
  try Ezjsonm.value_from_string s with
  | Ezjsonm.Parse_error (_, msg) ->
    Logger.fatal `JSONFormat msg

let read enc path =
  File.read path |> parse enc

let read_url enc url =
  Web.get url |> parse enc

let serialize ?(minify=true) enc data =
  data |> construct enc |> Ezjsonm.value_to_string ~minify

let write ?(minify=false) enc path data =
  data |> serialize ~minify enc |> File.write path

let to_string data = serialize ~minify:true Json_encoding.any_ezjson_value data
