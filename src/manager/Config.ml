open BantorraBasis
open File

let version = "1.0.0"

type lib_name = BantorraLibrary.Anchor.lib_name

type t = {libraries : (lib_name, string) Hashtbl.t}

let default = {libraries = Hashtbl.create 0}

module M =
struct
  let to_library : Marshal.value -> lib_name * string =
    function
    | `O ["name", name; "version", version; "root", root] ->
      {name = Marshal.to_string name; version = Marshal.to_ostring version},
      Marshal.to_string root
    | _ -> raise Marshal.IllFormed

  let of_library (({name; version} : lib_name), root) =
    `O ["name", Marshal.of_string name; "version", Marshal.of_ostring version; "root", Marshal.of_string root]
end

let deserialize : Marshal.value -> t =
  function
  | `O ["format", `String v; "libraries", `A libs] when v = version ->
    {libraries = Hashtbl.of_seq @@ Seq.map M.to_library @@ List.to_seq libs}
  | _ -> raise Marshal.IllFormed

let serialize ({libraries} : t) : Marshal.value =
  let libraries = List.of_seq @@ Seq.map M.of_library @@ Hashtbl.to_seq libraries in
  `O ["format", `String version; "libraries", `A libraries]

let config_filepath ~app_name =
  let app_config_home = OS.get_config_home () / app_name in
  File.ensure_dir app_config_home;
  app_config_home / "libraries"

let init ~app_name =
  let config = config_filepath ~app_name in
  try
    deserialize @@ Marshal.read_plain config
  with
  | _ ->
    try
      Marshal.write_plain config @@ serialize default;
      default
    with _ -> default

let length_libs {libraries} = Hashtbl.length libraries
let mem_libs {libraries} = Hashtbl.mem libraries
let find_libs {libraries} = Hashtbl.find libraries
