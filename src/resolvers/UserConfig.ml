open BantorraBasis
open BantorraBasis.File
open Bantorra

let version = "1.0.0"

type versioned_library =
  { name : string
  ; version : string option
  }
type filepath = string

type t = {dict : (versioned_library, filepath) Hashtbl.t}
let default () : t = {dict = Hashtbl.create 0}

type config = {dict : (versioned_library * filepath) list}
let default_config : config = {dict = []}

let library_in_use : (string, string) Hashtbl.t = Hashtbl.create 10

let cache : (string, t) Hashtbl.t = Hashtbl.create 0

module M =
struct
  let to_entries : Marshal.value -> (versioned_library * filepath) list =
    function
    | `O ["name", name; "version", version; "at", root] ->
      let name = Marshal.to_string name in
      let version = Marshal.to_ostring version in
      let root = File.normalize_dir @@ Marshal.to_string root in
      [{name; version}, root]
    | `O ["name", name; "versions", versions; "at", root] ->
      let name = Marshal.to_string name in
      let versions = Marshal.(to_list to_ostring) versions in
      let root = File.normalize_dir @@ Marshal.to_string root in
      if List.length versions = 0 then raise Marshal.IllFormed;
      List.map (fun version -> {name; version}, root) versions
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
    {dict = Util.Hashtbl.of_unique_seq @@ List.to_seq @@ List.concat_map M.to_entries dict}
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
    let conf = try deserialize @@ Marshal.read_json filepath with _ -> default () in
    Hashtbl.replace cache filepath conf;
    conf

(* XXX expensive List -> Hashtbl -> List conversion *)
let read ~app_name ~config =
  read_ ~app_name ~config |> fun ({dict} : t) ->
  {dict = List.of_seq @@ Hashtbl.to_seq dict}

(* XXX expensive List -> Hashtbl -> List conversion *)
let unsafe_write ~app_name ~config {dict} =
  let filepath = config_filepath ~app_name ~config in
  let conf : t = {dict = Util.Hashtbl.of_unique_seq @@ List.to_seq dict} in
  Marshal.unsafe_write_json filepath @@ serialize conf;
  Hashtbl.replace cache filepath conf

let clear_cached_configs () =
  Hashtbl.clear cache

let resolver ~app_name ~config =
  Resolver.make @@ fun ~current_root:_ arg ->
  try
    let conf = read_ ~app_name ~config in
    let {name; _} as arg = M.to_versioned_library arg in
    let root = Hashtbl.find conf.dict arg in
    match Hashtbl.find_opt library_in_use name with
    | None -> Hashtbl.replace library_in_use name root; Some root
    | Some root' -> if root' <> root then None else Some root
  with _ -> None
