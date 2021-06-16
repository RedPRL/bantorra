open File

type value = Ezjsonm.value

exception IllFormed

(* Even though the package json still has issues, it is important to have user-friendly syntax. *)
let of_json p = try p |> Ezjsonm.value_from_string with _ -> raise IllFormed
let read_json path = of_json @@ readfile path

let unsafe_to_json j = try j |> Ezjsonm.value_to_string ~minify:true with _ -> raise IllFormed
let unsafe_write_json path j = writefile path @@ unsafe_to_json j

let of_string s = `String s
let to_string : value -> string =
  function
  | `String s -> s
  | _ -> raise IllFormed

let of_ostring =
  function
  | None -> `Null
  | Some s -> `String s
let to_ostring =
  function
  | `String str -> Some str
  | `Null -> None
  | _ -> raise IllFormed

let of_list of_item l =
  `A (List.map of_item l)
let to_list to_item =
  function
  | `A items -> List.map to_item items
  | _ -> raise IllFormed

let of_float f = `Float f
let to_float =
  function
  | `Float f -> f
  | _ -> raise IllFormed

let dump v = Ezjsonm.value_to_string v
