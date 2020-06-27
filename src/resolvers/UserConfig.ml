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

let read_opt_ ~app_name ~config =
  try
    let filepath = config_filepath ~app_name ~config in
    match Hashtbl.find_opt cache filepath with
    | Some conf -> Some conf
    | None ->
      let conf = deserialize @@ Marshal.read_plain filepath in
      Hashtbl.replace cache filepath conf;
      Some conf
  with _ -> None

let try_read ~app_name ~config =
  Option.value ~default:(default ()) @@ read_opt_ ~app_name ~config

(* XXX expensive List -> Hashtbl -> List conversion *)
let read_opt ~app_name ~config =
  read_opt_ ~app_name ~config |> Option.map @@ fun ({dict} : t) ->
  {dict = List.of_seq @@ Hashtbl.to_seq dict}

(* XXX expensive List -> Hashtbl -> List conversion *)
let write ~app_name ~config {dict} =
  let filepath = config_filepath ~app_name ~config in
  let conf : t = {dict = Util.Hashtbl.of_unique_seq @@ List.to_seq dict} in
  Marshal.write_plain filepath @@ serialize conf;
  Hashtbl.replace cache filepath conf

let clear_cached_configs () =
  Hashtbl.clear cache

let resolver ~app_name ~config =
  let fast_checker ~cur_root:_ r =
    try
      let conf = try_read ~app_name ~config in
      Hashtbl.mem conf.dict @@ M.to_versioned_library r
    with _ -> false
  and resolver ~cur_root:_ r =
    try
      let conf = try_read ~app_name ~config in
      Hashtbl.find_opt conf.dict @@ M.to_versioned_library r
    with _ -> None
  in
  Resolver.make ~fast_checker resolver
