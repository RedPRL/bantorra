module E = Errors
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
  let to_info v =
    let src = "Waypoint.to_info" in
    Marshal.parse_object ~required:["name"] ~optional:["at"; "next_waypoint"; "next_as"] v >>=
    function
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
          E.error_format_msgf ~src "Cannot specify both `at' and `next_waypoint' in %a" Marshal.dump v
        | Some _, _, Some _ ->
          E.error_format_msgf ~src "Cannot specify both `at' and `next_as' in %a" Marshal.dump v
        | None, None, _ ->
          E.error_format_msgf ~src "Must specify at least `at' or `next_waypoint' in %a" Marshal.dump v
      end
    | _ -> assert false
end

let deserialize v =
  let src = "Waypoint.deserialize" in
  Marshal.parse_object ~required:["format"] ~optional:["waypoints"] v >>=
  function
  | ["format", format], ["waypoints", dict] ->
    let* format = Marshal.to_string format in
    let* dict = Option.value ~default:[] <$> Marshal.to_olist M.to_info dict in
    if format <> version then
      Errors.error_format_msgf ~src "Format version `%s' is not supported (only version `%s' is supported)" format version
    else begin
      match Util.Hashtbl.of_unique_list dict with
      | Error (`DuplicateKeys key) ->
        Errors.error_format_msgf ~src
          "Duplicate waypoints named `%s' in %a" key Marshal.dump v
      | Ok dict -> ret dict
    end
  | _ -> assert false

let get_waypoints ~landmark root =
  let src = "Waypoint.get_waypoints" in
  match Hashtbl.find_opt cache File.(root/landmark) with
  | Some waypoints -> ret waypoints
  | None ->
    match Marshal.read_json File.(root/landmark) >>= deserialize with
    | Error (`FormatError msg) ->
      E.append_error_invalid_library_msgf ~earlier:msg ~src
        "Could not parse the landmark file at %s" File.(root/landmark)
    | Error (`SystemError msg) ->
      E.append_error_invalid_library_msgf ~earlier:msg ~src
        "Could not read the landmark file at %s" File.(root/landmark)
    | Ok waypoints ->
      Hashtbl.replace cache root waypoints;
      ret waypoints

let clear_cached_landmarks () =
  Hashtbl.clear cache

let rec lookup_waypoint ~landmark current_dir lib_name k =
  let src = "Waypoint.lookup_waypoint" in
  let* waypoints = get_waypoints ~landmark current_dir in
  match Hashtbl.find_opt waypoints lib_name with
  | None -> k ()
  | Some (Direct {at}) ->
    begin
      match File.normalize_dir File.(current_dir/at) with
      | Error (`SystemError msg) ->
        E.append_error_invalid_library_msgf ~earlier:msg ~src
          "Could not load the library at %s" File.(current_dir/at)
      | Ok root -> ret root
    end
  | Some Indirect {next_waypoint; next_as} ->
    let current_dir = File.(current_dir/next_waypoint) in
    let lib_name = Option.value ~default:lib_name next_as in
    lookup_waypoint ~landmark current_dir lib_name @@ fun () ->
    E.error_invalid_library_msgf ~src
      "Could not find a waypoint named `%s' in %s" lib_name File.(current_dir/next_waypoint)

let rec lookup_waypoint_in_ancestors ~landmark current_dir lib_name =
  let src = "Waypoint.lookup_waypoint_in_ancestors" in
  match File.locate_anchor ~anchor:landmark current_dir with
  | Error (`AnchorNotFound msg) ->
    E.append_error_invalid_library_msgf ~earlier:msg ~src
      "Could not find files named `%s' all the way up to the root" landmark
  | Ok (current_dir, _) ->
    lookup_waypoint ~landmark current_dir lib_name @@ fun () ->
    match File.parent_of_normalized_dir current_dir with
    | None ->
      E.error_invalid_library_msgf ~src
        "Could not find a waypoint named `%s' in all landmarks (files named `%s') all the way up to the root" lib_name landmark
    | Some parent -> lookup_waypoint_in_ancestors ~landmark parent lib_name

let router ?(eager_resolution=false) ~landmark =
  let route ~starting_dir arg =
    let src = "Waypoint.route" in
    match Marshal.to_string arg with
    | Error (`FormatError msg) ->
      E.append_error_invalid_library_msgf ~earlier:msg ~src
        "Could not parse the argument: %a" Marshal.dump arg
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
