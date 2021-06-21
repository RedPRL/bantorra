open ResultMonad.Syntax
open File

type value = Ezjsonm.value

let of_json p =
  try ret @@ Ezjsonm.value_from_string p with
  | Ezjsonm.Parse_error (_, s) -> error @@ `FormatError s
let read_json path = readfile path >>= of_json

let to_json ?(minify=true) j = Ezjsonm.value_to_string ~minify j
let write_json ?minify path j = writefile path @@ to_json ?minify j

let invalid_arg ~f v =
  Printf.ksprintf (fun s -> error @@ `FormatError (Printf.sprintf "%s on %s: %s" f (to_json ~minify:true v) s))

let of_string s = `String s
let to_string : value -> (string, [> `FormatError of string]) result =
  function
  | `String s -> ret s
  | v -> invalid_arg ~f:"to_string" v "not a string"

let of_ostring =
  function
  | None -> `Null
  | Some s -> `String s
let to_ostring =
  function
  | `String str -> ret @@ Some str
  | `Null -> ret None
  | v -> invalid_arg ~f:"to_ostring" v "not a null or a string"

let of_list of_item l =
  `A (List.map of_item l)
let to_list to_item =
  function
  | `A items -> ResultMonad.map to_item items
  | v -> invalid_arg ~f:"of_list" v "not a list"

let of_olist of_item =
  function
  | None -> `Null
  | Some l -> of_list of_item l
let to_olist to_item =
  function
  | `A items ->
    let+ l = ResultMonad.map to_item items in Some l
  | `Null -> ret None
  | v -> invalid_arg ~f:"of_olist" v "not a null or a list"

let dump v = Ezjsonm.value_to_string v

let parse_object_fields ?(required=[]) ?(optional=[]) ms =
  let fields = Hashtbl.create 10 in
  let* () = ResultMonad.iter (fun f ->
      match Hashtbl.find_opt fields f with
      | Some _ -> invalid_arg ~f:"parse_object_fields" (`O ms) "duplicate fields %s in the specification" f
      | None -> ret @@ Hashtbl.replace fields f None
    ) (required @ optional)
  in
  let* () =
    ResultMonad.iter (fun (f, v) ->
        match Hashtbl.find_opt fields f with
        | None ->
          invalid_arg ~f:"parse_object_fields" (`O ms) "unexpected field %s" f
        | Some (Some _) ->
          invalid_arg ~f:"parse_object_fields" (`O ms) "duplicate fields %s" f
        | Some None ->
          ret @@ Hashtbl.replace fields f (Some v)
      ) ms
  in
  let* values_requred = ResultMonad.map (fun f ->
      match Hashtbl.find fields f with
      | Some v -> ret (f, v)
      | None -> invalid_arg ~f:"parse_object_fields" (`O ms) "field %s missing" f
    ) required
  and* values_optional = ResultMonad.map (fun f ->
      match Hashtbl.find fields f with
      | Some v -> ret (f, v)
      | None -> ret (f, `Null)
    ) optional
  in
  ret (values_requred, values_optional)
