open BantorraBasis
open BantorraBasis.File
open Bantorra

let version = "1.0.0"

type info =
  { name : string
  ; version : string option
  }

type t = {dict : (info, string) Hashtbl.t}

let default = {dict = Hashtbl.create 0}

module M =
struct
  let to_entry : Marshal.value -> info * string =
    function
    | `O ["name", name; "version", version; "at", root] ->
      {name = Marshal.to_string name; version = Marshal.to_ostring version},
      Marshal.to_string root
    | _ -> raise Marshal.IllFormed

  let of_entry (({name; version} : info), root) =
    `O ["name", Marshal.of_string name; "version", Marshal.of_ostring version; "root", Marshal.of_string root]

  let to_info : Marshal.value -> info =
    function
    | `O ["name", name; "version", version] ->
      {name = Marshal.to_string name; version = Marshal.to_ostring version}
    | _ -> raise Marshal.IllFormed
end

let deserialize : Marshal.value -> t =
  function
  | `O ["format", `String v; "libraries", `A dict] when v = version ->
    {dict = Hashtbl.of_seq @@ Seq.map M.to_entry @@ List.to_seq dict}
  | _ -> raise Marshal.IllFormed

let serialize ({dict} : t) : Marshal.value =
  let dict = List.of_seq @@ Seq.map M.of_entry @@ Hashtbl.to_seq dict in
  `O ["format", `String version; "libraries", `A dict]

let config_filepath ~app_name =
  let app_config_home = Xdg.get_config_home ~app_name in
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

let resolver ~app_name =
  let config = init ~app_name in
  let checker ~cur_root:_ r = try Hashtbl.mem config.dict @@ M.to_info r with _ -> false
  and resolver ~cur_root:_ r = try Hashtbl.find_opt config.dict @@ M.to_info r with _ -> None
  in
  Resolver.make ~checker resolver
