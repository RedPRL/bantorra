open File

type value = Ezjsonm.value
type yaml = Yaml.yaml
type t = Ezjsonm.t

exception IllFormed

let digest v = try v |> Yaml.to_string_exn |> Digest.string with _ -> raise IllFormed

(* Ezjsonm is needed because yaml failed to reconstruct quoted keywords such as ["true"]. *)
let of_gzip z = try z |> Ezgzip.decompress |> Result.get_ok |> Ezjsonm.from_string with _ -> raise IllFormed
let to_gzip j = try j |> Ezjsonm.to_string ~minify:true |> Ezgzip.compress with _ -> raise IllFormed
let write_gzip path j = writefile path @@ to_gzip j
let read_gzip path = of_gzip @@ readfile path

(* Even though yaml still has issues, it is important to have user-friendly syntax. *)
let of_plain p = try p |> Yaml.of_string_exn with _ -> raise IllFormed
let to_plain j = try j |> Yaml.to_string_exn ~layout_style:`Block with _ -> raise IllFormed
let write_plain path j = writefile path @@ to_plain j
let read_plain path = of_plain @@ readfile path

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

let dump = Ezjsonm.value_to_string ~minify:true
