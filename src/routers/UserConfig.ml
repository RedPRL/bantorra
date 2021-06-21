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
  let to_entries =
    function
    | `O ms as v ->
      Marshal.parse_object_fields ~required:["name"; "at"] ~optional:["version"; "versions"] ms >>=
      begin function
        | ["name", name; "at", root],
          ["version", version; "versions", versions] ->
          begin
            let* name = Marshal.to_string name in
            let* root = File.expand_home <$> Marshal.to_string root in
            let* versions =
              let* version = Marshal.to_ostring version in
              let* versions = Marshal.(to_olist to_ostring) versions in
              match version, versions with
              | Some _, Some _ ->
                Marshal.invalid_arg ~f:"UserConfig.deserialize" v "cannot specify both `version' and `versions'"
              | _, Some [] ->
                Marshal.invalid_arg ~f:"UserConfig.deserialize" v "field `versions' is an empty list"
              | version, None -> ret [version]
              | None, Some versions -> ret versions
            in
            match File.normalize_dir root with
            | Error (`SystemError msg) -> Marshal.invalid_arg ~f:"UserConfig.deserialize" v "%s" msg
            | Ok root ->
              ret @@ List.map (fun version -> {name; version}, root) versions
          end
        | _ -> assert false
      end
    | v ->
      Marshal.invalid_arg ~f:"UserConfig.deserialize" v "invalid entry"

  let of_entry (({name; version} : versioned_library), root) =
    `O ["name", Marshal.of_string name;
        "version", Marshal.of_ostring version;
        "root", Marshal.of_string root]

  let to_versioned_library =
    function
    | `O ms ->
      Marshal.parse_object_fields ~required:["name"] ~optional:["version"] ms >>=
      begin function
        | ["name", name], ["version", version] ->
          let* name = Marshal.to_string name in
          let* version = Marshal.to_ostring version in
          ret {name; version}
        | _ -> assert false
      end
    | v -> Marshal.invalid_arg ~f:"UserConfig.to_versioned_library" v "invalid argument"
end

let deserialize : Marshal.value -> _ =
  function
  | `O ms as v ->
    Marshal.parse_object_fields ~required:["format"] ~optional:["libraries"] ms >>=
    begin function
      | ["format", format], ["libraries", dict] ->
        let* format = Marshal.to_string format in
        if format <> version then
          Marshal.invalid_arg ~f:"UserConfig.deserialize" v "unsupported version %s" format
        else begin
          let* dict = Option.fold ~none:[] ~some:List.concat <$> Marshal.to_olist M.to_entries dict in
          match Util.Hashtbl.of_unique_seq @@ List.to_seq dict with
          | Error (`DuplicateKeys key) ->
            Marshal.invalid_arg ~f:"UserConfig.deserialize" v
              "duplicate libraries with name = %s and version %s"
              key.name (string_of_version key.version)
          | Ok dict -> ret {dict}
        end
      | _ -> assert false
    end
  | v -> Marshal.invalid_arg ~f:"UserConfig.deserialize" v "invalid configuration file"

let serialize ({dict} : t) : Marshal.value =
  let dict = List.of_seq @@ Seq.map M.of_entry @@ Hashtbl.to_seq dict in
  `O ["format", `String version; "libraries", `A dict]

let config_dir ?xdg_as_linux ~app_name =
  File.get_xdg_config_home ?as_linux:xdg_as_linux ~app_name

let config_filepath ?xdg_as_linux ~app_name ~config =
  File.(config_dir ?xdg_as_linux ~app_name / config)

let read ?xdg_as_linux ~app_name ~config =
  let filepath = config_filepath ?xdg_as_linux ~app_name ~config in
  match Hashtbl.find_opt cache filepath with
  | Some conf -> ret conf
  | None ->
    let* conf =
      if Sys.file_exists filepath then
        Marshal.read_json filepath >>= deserialize
      else
        ret default_config
    in
    Hashtbl.replace cache filepath conf;
    ret conf

let lookup ~name ~version config =
  Hashtbl.find_opt config.dict {name; version}

let write ?xdg_as_linux ~app_name ~config conf =
  let* () = File.ensure_dir @@ config_dir ?xdg_as_linux ~app_name in
  let filepath = config_filepath ?xdg_as_linux ~app_name ~config in
  let* () = Marshal.write_json ~minify:false filepath @@ serialize conf in
  ret @@ Hashtbl.replace cache filepath conf

let clear_cached_configs () =
  Hashtbl.clear cache

let router ?xdg_as_linux ~app_name ~config =
  Router.make @@ fun ~starting_dir:_ arg ->
  match
    let* conf = read ?xdg_as_linux ~app_name ~config in
    let* arg = M.to_versioned_library arg in
    match Hashtbl.find_opt conf.dict arg with
    | None ->
      Router.library_load_error
        "UserConfig.route: no library with name = %s and version = %s"
        arg.name (string_of_version arg.version)
    | Some root ->
      match Hashtbl.find_opt library_in_use arg.name with
      | None -> Hashtbl.replace library_in_use arg.name root; ret root
      | Some root' ->
        if root' <> root then
          Router.library_load_error
            "UserConfig.route: attempting to load library %s from %s, but it's already loaded from %s"
            arg.name root root'
        else
          ret root
  with
  | Ok lib -> ret lib
  | Error (`SystemError msg | `FormatError msg) -> Router.library_load_error "UserConfig.route: %s" msg
  | Error (`InvalidLibrary _) as e -> e
