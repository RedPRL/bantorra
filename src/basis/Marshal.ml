module E = Errors
open ResultMonad.Syntax
open File

type value = Ezjsonm.value

let of_json p =
  let src = "Marshal.of_json" in
  try ret @@ Ezjsonm.value_from_string p with
  | Ezjsonm.Parse_error (_, msg) -> E.error_format_msg ~src msg
let read_json path = readfile path >>= of_json

let to_json ?(minify=true) j = Ezjsonm.value_to_string ~minify j
let write_json ?minify path j = writefile path @@ to_json ?minify j

let dump fmt j = Format.pp_print_string fmt (to_json ~minify:true j)

let of_string s = `String s
let to_string : value -> (string, [> `FormatError of string]) result =
  let src = "Marshal.to_string" in
  function
  | `String s -> ret s
  | v -> E.error_format_msgf ~src "Not a string: %a" dump v

let of_ostring =
  function
  | None -> `Null
  | Some s -> `String s
let to_ostring =
  let src = "Marshal.to_ostring" in
  function
  | `String str -> ret @@ Some str
  | `Null -> ret None
  | v -> E.error_format_msgf ~src "Not a string or null: %a" dump v

let of_list of_item l =
  `A (List.map of_item l)
let to_list to_item =
  let src = "Marshal.to_list" in
  function
  | `A items -> ResultMonad.map to_item items
  | v -> E.error_format_msgf ~src "Not a list: %a" dump v

let of_olist of_item =
  function
  | None -> `Null
  | Some l -> of_list of_item l
let to_olist to_item =
  let src = "Marshal.to_olist" in
  function
  | `A items ->
    let+ l = ResultMonad.map to_item items in Some l
  | `Null -> ret None
  | v -> E.error_format_msgf ~src "Not a list or null: %a" dump v

let parse_object_fields ?(required=[]) ?(optional=[]) ms =
  let src = "Marshal.parse_object_fields" in
  let fields = Hashtbl.create 10 in
  let* () = ResultMonad.iter (fun f ->
      match Hashtbl.find_opt fields f with
      | Some _ ->
        E.error_format_msgf ~src "Duplicate fields `%s' in the field specification." f
      | None -> ret @@ Hashtbl.replace fields f None
    ) (required @ optional)
  in
  let* () =
    ResultMonad.iter (fun (f, v) ->
        match Hashtbl.find_opt fields f with
        | None ->
          E.error_format_msgf ~src "Unexpected field `%s' in %a" f dump (`O ms)
        | Some (Some _) ->
          E.error_format_msgf ~src "Duplicate fields `%s' in %a" f dump (`O ms)
        | Some None ->
          ret @@ Hashtbl.replace fields f (Some v)
      ) ms
  in
  let* values_requred = ResultMonad.map (fun f ->
      match Hashtbl.find fields f with
      | Some v -> ret (f, v)
      | None ->
        E.error_format_msgf ~src "Required field `%s' missing in %a" f dump (`O ms)
    ) required
  and* values_optional = ResultMonad.map (fun f ->
      match Hashtbl.find fields f with
      | Some v -> ret (f, v)
      | None -> ret (f, `Null)
    ) optional
  in
  ret (values_requred, values_optional)

let parse_object ?required ?optional =
  let src = "Marshal.parse_object" in
  function
  | `O ms -> parse_object_fields ?required ?optional ms
  | v -> E.error_format_msgf ~src "Not an object: %a" dump v

let parse_object_or_null ?required ?optional =
  let src = "Marshal.parse_object_or_null" in
  function
  | `Null -> ret None
  | `O ms -> Option.some <$> parse_object_fields ?required ?optional ms
  | v -> E.error_format_msgf ~src "Not an object or null: %a" dump v
