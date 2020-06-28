open File

type value = Yaml.value

exception IllFormed

(* Even though the package yaml still has issues, it is important to have user-friendly syntax. *)
let of_yaml p = try p |> Yaml.of_string_exn with _ -> raise IllFormed
let read_yaml path = of_yaml @@ readfile path

let unsafe_to_yaml j = try j |> Yaml.to_string_exn ~layout_style:`Block with _ -> raise IllFormed
let unsafe_write_yaml path j = writefile path @@ unsafe_to_yaml j

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

let dump v = Result.get_ok @@ Yaml.to_string ~layout_style:`Flow v
