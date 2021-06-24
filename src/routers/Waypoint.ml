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
  let to_info ~starting_dir v =
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
          let* at = File.input_absolute_dir ~starting_dir at in
          ret (name, Direct {at})
        | None, Some next_waypoint, next_as ->
          let* next_waypoint = File.input_absolute_dir ~starting_dir next_waypoint in
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

let deserialize ~starting_dir v =
  let src = "Waypoint.deserialize" in
  Marshal.parse_object ~required:["format"] ~optional:["waypoints"] v >>=
  function
  | ["format", format], ["waypoints", dict] ->
    let* format = Marshal.to_string format in
    let* dict = Option.value ~default:[] <$> Marshal.to_olist (M.to_info ~starting_dir) dict in
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

let get_waypoints ~landmark ~starting_dir =
  let src = "Waypoint.get_waypoints" in
  match Hashtbl.find_opt cache File.(starting_dir/landmark) with
  | Some waypoints -> ret waypoints
  | None ->
    match Marshal.read_json File.(starting_dir/landmark) >>= deserialize ~starting_dir with
    | Error (`FormatError msg) ->
      E.append_error_invalid_library_msgf ~earlier:msg ~src
        "Could not parse the landmark file at %s" File.(starting_dir/landmark)
    | Error (`SystemError msg) ->
      E.append_error_invalid_library_msgf ~earlier:msg ~src
        "Could not read the landmark file at %s" File.(starting_dir/landmark)
    | Ok waypoints ->
      Hashtbl.replace cache starting_dir waypoints;
      ret waypoints

let clear_cached_landmarks () =
  Hashtbl.clear cache

let rec lookup_waypoint ~max_depth ~depth ~landmark ~starting_dir lib_name k =
  let src = "Waypoint.lookup_waypoint" in
  if depth > max_depth then
    E.error_invalid_library_msgf ~src "Waypoint resolution stack overflow (max depth = %i)." max_depth
  else
    let* waypoints = get_waypoints ~landmark ~starting_dir in
    match Hashtbl.find_opt waypoints lib_name with
    | None -> k ()
    | Some (Direct {at}) -> ret at
    | Some Indirect {next_waypoint = starting_dir; next_as} ->
      let depth = depth + 1 in
      let lib_name = Option.value ~default:lib_name next_as in
      lookup_waypoint ~max_depth ~depth ~landmark ~starting_dir lib_name @@ fun () ->
      E.error_invalid_library_msgf ~src
        "Could not find a waypoint named `%s' in %s" lib_name starting_dir

let rec lookup_waypoint_in_ancestors ~max_depth ~depth ~landmark ~starting_dir lib_name =
  let src = "Waypoint.lookup_waypoint_in_ancestors" in
  if depth > max_depth then
    E.error_invalid_library_msgf ~src "Waypoint resolution stack overflow (max depth = %i)." max_depth
  else
    match File.locate_anchor ~anchor:landmark starting_dir with
    | Error (`AnchorNotFound msg) ->
      E.append_error_invalid_library_msgf ~earlier:msg ~src
        "Could not find files named `%s' all the way up to the root" landmark
    | Ok (starting_dir, _) ->
      lookup_waypoint ~max_depth ~depth ~landmark ~starting_dir lib_name @@ fun () ->
      match File.parent_of_normalized_dir starting_dir with
      | None ->
        E.error_invalid_library_msgf ~src
          "Could not find a waypoint named `%s' in all landmarks (files named `%s')\
           all the way up to the root" lib_name landmark
      | Some parent -> lookup_waypoint_in_ancestors ~max_depth ~depth ~landmark ~starting_dir:parent lib_name

let router ?(max_depth=100) ?(eager_resolution=false) ~landmark =
  let fast_checker =
    if eager_resolution then None
    else Option.some @@ fun ~starting_dir:_ ~arg ->
      try Result.is_ok @@ Marshal.to_string arg with _ -> false
  in
  Router.make ?fast_checker @@ fun ~starting_dir ~arg ->
  let src = "Waypoint.route" in
  match Marshal.to_string arg with
  | Error (`FormatError msg) ->
    E.append_error_invalid_library_msgf ~earlier:msg ~src
      "Could not parse the argument: %a" Marshal.dump arg
  | Ok arg ->
    lookup_waypoint_in_ancestors ~max_depth ~depth:0 ~landmark ~starting_dir arg
