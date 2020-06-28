open BantorraBasis
open BantorraBasis.File
open Bantorra

let version = "1.0.0"

type versioned_library =
  { name : string
  ; version : string option
  }

type t = {dict : (versioned_library, string) Hashtbl.t}
let default () : t = {dict = Hashtbl.create 0}

type config = {dict : (versioned_library * string) list}
let default_config : config = {dict = []}

let library_in_use : (string, string) Hashtbl.t = Hashtbl.create 10

let cache : (string, t) Hashtbl.t = Hashtbl.create 0

module M =
struct
  let to_entry : Marshal.value -> versioned_library * string =
    function
    | `O ["name", name; "version", version; "at", root] ->
      {name = Marshal.to_string name; version = Marshal.to_ostring version},
      File.normalize_dir @@ Marshal.to_string root
    | _ -> raise Marshal.IllFormed

  let of_entry (({name; version} : versioned_library), root) =
    `O ["name", Marshal.of_string name; "version", Marshal.of_ostring version; "root", Marshal.of_string root]

  let to_versioned_library : Marshal.value -> versioned_library =
    function
    | `O ms ->
      begin
        match List.sort Stdlib.compare ms with
        | ["name", name; "version", version] ->
          {name = Marshal.to_string name; version = Marshal.to_ostring version}
        | ["name", name] ->
          {name = Marshal.to_string name; version = None}
        | _ -> raise Marshal.IllFormed
      end
    | _ -> raise Marshal.IllFormed
end

let deserialize : Marshal.value -> t =
  function
  | `O ["format", `String v; "libraries", `A dict] when v = version ->
    {dict = Util.Hashtbl.of_unique_seq @@ Seq.map M.to_entry @@ List.to_seq dict}
  | _ -> raise Marshal.IllFormed

let serialize ({dict} : t) : Marshal.value =
  let dict = List.of_seq @@ Seq.map M.of_entry @@ Hashtbl.to_seq dict in
  `O ["format", `String version; "libraries", `A dict]

let config_filepath ~app_name ~config =
  Xdg.get_config_home ~app_name / config

let read_ ~app_name ~config =
  let filepath = config_filepath ~app_name ~config in
  match Hashtbl.find_opt cache filepath with
  | Some conf -> conf
  | None ->
    let conf = try deserialize @@ Marshal.read_yaml filepath with _ -> default () in
    Hashtbl.replace cache filepath conf;
    conf

(* XXX expensive List -> Hashtbl -> List conversion *)
let read ~app_name ~config =
  read_ ~app_name ~config |> fun ({dict} : t) ->
  {dict = List.of_seq @@ Hashtbl.to_seq dict}

(* XXX expensive List -> Hashtbl -> List conversion *)
(* XXX Yaml.of_string does not quote strings properly *)
let unsafe_write ~app_name ~config {dict} =
  let filepath = config_filepath ~app_name ~config in
  let conf : t = {dict = Util.Hashtbl.of_unique_seq @@ List.to_seq dict} in
  Marshal.unsafe_write_yaml filepath @@ serialize conf;
  Hashtbl.replace cache filepath conf

let clear_cached_configs () =
  Hashtbl.clear cache

let resolver ~app_name ~config =
  let resolver ~cur_root:_ arg =
    try
      let conf = read_ ~app_name ~config in
      let {name; _} as arg = M.to_versioned_library arg in
      let root = Hashtbl.find conf.dict arg in
      match Hashtbl.find_opt library_in_use name with
      | None -> Hashtbl.replace library_in_use name root; Some root
      | Some root' -> if root' <> root then None else Some root
    with _ -> None
  in
  Resolver.make resolver
