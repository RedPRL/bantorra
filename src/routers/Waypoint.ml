open BantorraBasis
open ResultMonad.Syntax
open Bantorra

let version = "1.0.0"

type info =
  | Direct of {at: File.filepath}
  | Indirect of {next_waypoint: File.filepath; next_as: string option}

type t = (string, info) Hashtbl.t

let cache : (string, t) Hashtbl.t = Hashtbl.create 10

module M =
struct
  let to_info =
    function
    | `O ms as v ->
      Marshal.parse_object_fields ~required:["name"] ~optional:["at"; "next_waypoint"; "next_as"] ms >>=
      begin function
        | ["name", name], ["at", at; "next_waypoint", next_waypoint; "next_as", next_as] ->
          let* name = Marshal.to_string name in
          let* at = Marshal.to_ostring at in
          let* next_waypoint = Marshal.to_ostring next_waypoint in
          let* next_as = Marshal.to_ostring next_as in
          begin match at, next_waypoint, next_as with
            | Some at, None, None ->
              ret (name, Direct {at})
            | None, Some next_waypoint, next_as ->
              ret (name, Indirect {next_waypoint; next_as})
            | Some _, Some _, _ ->
              Marshal.invalid_arg ~f:"Waypoint.deserialize" v "cannot specify both `at' and `next_waypoint'"
            | Some _, _, Some _ ->
              Marshal.invalid_arg ~f:"Waypoint.deserialize" v "cannot specify both `at' and `next_as'"
            | None, None, _ ->
              Marshal.invalid_arg ~f:"Waypoint.deserialize" v "must specify at least `at' or `next_waypoint'"
          end
        | _ -> assert false
      end
    | v -> Marshal.invalid_arg ~f:"Waypoint.deserialize" v "not an object"
end

let deserialize : Marshal.value -> _ =
  function
  | `O ms as v ->
    Marshal.parse_object_fields ~required:["format"] ~optional:["waypoints"] ms >>=
    begin function
      | ["format", format], ["waypoints", dict] ->
        let* format = Marshal.to_string format in
        let* dict = Option.value ~default:[] <$> Marshal.to_olist M.to_info dict in
        if format <> version then
          Marshal.invalid_arg ~f:"Waypoint.deserialize" v "unsupported version %s" format
        else begin
          match Util.Hashtbl.of_unique_list dict with
          | Error (`DuplicateKeys key) ->
            Marshal.invalid_arg ~f:"Waypoint.deserialize" v
              "duplicate waypoints with name = %s" key
          | Ok dict -> ret dict
        end
      | _ -> assert false
    end
  | v -> Marshal.invalid_arg ~f:"Waypoint.deserialize" v "not an object"

let get_waypoints ~landmark root =
  match Hashtbl.find_opt cache File.(root/landmark) with
  | Some waypoints -> ret waypoints
  | None ->
    match Marshal.read_json File.(root/landmark) >>= deserialize with
    | Error (`FormatError msg) ->
      Router.library_load_error "Waypoint.route: the landmark %s is ill-formed: %s" File.(root/landmark) msg
    | Error (`SystemError msg) ->
      Router.library_load_error "Waypoint.route: could not read the landmark %s: %s" File.(root/landmark) msg
    | Ok waypoints ->
      Hashtbl.replace cache root waypoints;
      ret waypoints

let clear_cached_landmarks () =
  Hashtbl.clear cache

let rec lookup_waypoint ~landmark current_dir lib_name k =
  let* waypoints = get_waypoints ~landmark current_dir in
  match Hashtbl.find_opt waypoints lib_name with
  | None -> k ()
  | Some (Direct {at}) ->
    begin
      match File.normalize_dir File.(current_dir/at) with
      | Error (`SystemError msg) ->
        Router.library_load_error "Waypoint.route: %s" msg
      | Ok root -> ret root
    end
  | Some Indirect {next_waypoint; next_as} ->
    let current_dir = File.(current_dir/next_waypoint) in
    let lib_name = Option.value ~default:lib_name next_as in
    lookup_waypoint ~landmark current_dir lib_name @@ fun () ->
    Router.library_load_error "Waypoint.route: cannot find the waypoint for %s" lib_name

let rec lookup_waypoint_in_ancestors ~landmark current_dir lib_name =
  match File.locate_anchor ~anchor:landmark current_dir with
  | Error (`AnchorNotFound msg) ->
    Router.library_load_error "Waypoint.route: no files named `%s' found all the way up to the root: %s" landmark msg
  | Ok (current_dir, _) ->
    lookup_waypoint ~landmark current_dir lib_name @@ fun () ->
    match File.parent_of_normalized_dir current_dir with
    | None ->
      Router.library_load_error "Waypoint.route: %s not in any landmark all the way up to the root" lib_name
    | Some parent -> lookup_waypoint_in_ancestors ~landmark parent lib_name

let router ?(eager_resolution=false) ~landmark =
  let route ~starting_dir arg =
    match Marshal.to_string arg with
    | Error (`FormatError msg) ->
      Router.library_load_error "Waypoint.route: %s" msg
    | Ok arg ->
      lookup_waypoint_in_ancestors ~landmark starting_dir arg
  in
  let fast_checker ~starting_dir arg =
    if eager_resolution then
      try Result.is_ok @@ route ~starting_dir arg with _ -> false
    else
      try Result.is_ok @@ Marshal.to_string arg with _ -> false
  in
  Router.make ~fast_checker route
