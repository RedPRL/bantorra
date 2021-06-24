module E = Errors
open BantorraBasis
open ResultMonad.Syntax
open Bantorra

let version = "1.0.0"

type versioned_library =
  { name : string
  ; version : string option
  }
let string_of_version = Option.value ~default:"<null>"

type config = {dict : (versioned_library, File.filepath) Hashtbl.t}
type t = config
let default_config : t = {dict = Hashtbl.create 0}

let library_in_use : (string, File.filepath) Hashtbl.t = Hashtbl.create 10

let cache : (string, t) Hashtbl.t = Hashtbl.create 0

module M =
struct
  let to_entries v =
    let src = "UserConfig.to_entries" in
    Marshal.parse_object ~required:["name"; "at"] ~optional:["version"; "versions"] v >>=
    function
    | ["name", name; "at", root],
      ["version", version; "versions", versions] ->
      begin
        let* name = Marshal.to_string name in
        let* root = Marshal.to_string root in
        let* versions =
          let* version = Marshal.to_ostring version in
          let* versions = Marshal.(to_olist to_ostring) versions in
          match version, versions with
          | Some _, Some _ ->
            E.error_format_msgf ~src "Cannot specify both `version' and `versions' in %a" Marshal.dump v
          | _, Some [] ->
            E.error_format_msgf ~src "Field `versions' cannot be an empty list in %a" Marshal.dump v
          | version, None -> ret [version]
          | None, Some versions -> ret versions
        in
        match File.normalize_dir (File.expand_home root) with
        | Error (`SystemError msg) ->
          E.append_error_format_msgf ~earlier:msg ~src "Could not normalize the path %s" root
        | Ok root ->
          ret @@ List.map (fun version -> {name; version}, root) versions
      end
    | _ -> assert false

  let of_entry (({name; version} : versioned_library), root) =
    `O ["name", Marshal.of_string name;
        "version", Marshal.of_ostring version;
        "root", Marshal.of_string root]

  let to_versioned_library v =
    Marshal.parse_object ~required:["name"] ~optional:["version"] v >>=
    function
    | ["name", name], ["version", version] ->
      let* name = Marshal.to_string name in
      let* version = Marshal.to_ostring version in
      ret {name; version}
    | _ -> assert false
end

let deserialize v =
  let src = "UserConfig.deserialize" in
  Marshal.parse_object ~required:["format"] ~optional:["libraries"] v >>=
  function
  | ["format", format], ["libraries", dict] ->
    let* format = Marshal.to_string format in
    if format <> version then
      Errors.error_format_msgf ~src "Format version `%s' is not supported (only version `%s' is supported)" format version
    else begin
      let* dict = Option.fold ~none:[] ~some:List.concat <$> Marshal.to_olist M.to_entries dict in
      match Util.Hashtbl.of_unique_seq @@ List.to_seq dict with
      | Error (`DuplicateKeys key) ->
        Errors.error_format_msgf ~src
          "Duplicate libraries with name = %s and version %s"
          key.name (string_of_version key.version)
      | Ok dict -> ret {dict}
    end
  | _ -> assert false

let serialize ({dict} : t) : Marshal.value =
  let dict = List.of_seq @@ Seq.map M.of_entry @@ Hashtbl.to_seq dict in
  `O ["format", `String version; "libraries", `A dict]

let config_dir ?xdg_macos_as_linux ~app_name =
  File.get_xdg_config_home ?macos_as_linux:xdg_macos_as_linux ~app_name

let config_filepath ?xdg_macos_as_linux ~app_name ~config =
  let+ config_dir = config_dir ?xdg_macos_as_linux ~app_name in
  File.(config_dir / config)

let read ?xdg_macos_as_linux ~app_name ~config =
  let* filepath = config_filepath ?xdg_macos_as_linux ~app_name ~config in
  match Hashtbl.find_opt cache filepath with
  | Some conf -> ret conf
  | None ->
    let* conf =
      if File.file_exists filepath then
        Marshal.read_json filepath >>= deserialize
      else
        ret default_config
    in
    Hashtbl.replace cache filepath conf;
    ret conf

let lookup ~name ~version config =
  Hashtbl.find_opt config.dict {name; version}

let write ?xdg_macos_as_linux ~app_name ~config conf =
  let* () = config_dir ?xdg_macos_as_linux ~app_name >>= File.ensure_dir in
  let* filepath = config_filepath ?xdg_macos_as_linux ~app_name ~config in
  let* () = Marshal.write_json ~minify:false filepath @@ serialize conf in
  ret @@ Hashtbl.replace cache filepath conf

let clear_cached_configs () =
  Hashtbl.clear cache

let router ?xdg_macos_as_linux ~app_name ~config =
  Router.make @@ fun ~starting_dir:_ arg ->
  let src = "UserConfig.route" in
  match
    let* conf = read ?xdg_macos_as_linux ~app_name ~config in
    let* arg = M.to_versioned_library arg in
    match Hashtbl.find_opt conf.dict arg with
    | None ->
      E.error_invalid_library_msgf ~src
        "No such library with name = %s and version = %s"
        arg.name (string_of_version arg.version)
    | Some root ->
      match Hashtbl.find_opt library_in_use arg.name with
      | None -> Hashtbl.replace library_in_use arg.name root; ret root
      | Some root' ->
        if root' <> root then
          E.error_invalid_library_msgf ~src
            "Attempting to load library %s from %s, but it was already loaded from %s"
            arg.name root root'
        else
          ret root
  with
  | Ok lib -> ret lib
  | Error (`SystemError msg | `FormatError msg) ->
    E.append_error_invalid_library_msgf ~earlier:msg ~src
      "Could not load the library specified by %a" Marshal.dump arg
  | Error (`InvalidLibrary _) as e -> e
