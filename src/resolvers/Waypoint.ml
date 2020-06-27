open BantorraBasis
open BantorraBasis.File
open Bantorra

let version = "1.0.0"

type info = Direct of {at: string list} | Indirect of {next: string list; rename: string option}

type t = (string, info) Hashtbl.t

let cache : (string, t) Hashtbl.t = Hashtbl.create 10

module M =
struct
  let to_info : Marshal.value -> info =
    function
    | `O ms ->
      begin
        match List.sort Stdlib.compare ms with
        | ["at", at] ->
          Direct {at = Marshal.(to_list to_string at)}
        | ["next", next] ->
          Indirect {next = Marshal.(to_list to_string next); rename = None}
        | ["next", next; "rename", `String rename] ->
          Indirect {next = Marshal.(to_list to_string next); rename = Some rename}
        | _ -> raise Marshal.IllFormed
      end
    | _ -> raise Marshal.IllFormed
end

let deserialize : Marshal.value -> t =
  function
  | `O ["format", `String v; "waypoints", `O dict] when v = version ->
    Util.Hashtbl.of_unique_seq @@ Seq.map (fun (n, i) -> n, M.to_info i) @@ List.to_seq dict
  | _ -> raise Marshal.IllFormed

let get_waypoints ~landmark root =
  match Hashtbl.find_opt cache @@ root / landmark with
  | Some waypoints -> waypoints
  | None ->
    let waypoints = deserialize @@ Marshal.read_plain @@ root / landmark in
    Hashtbl.replace cache root waypoints;
    waypoints

let clear_cached_landmarks () =
  Hashtbl.clear cache

(* XXX errors are not handled *)
let rec lookup_waypoint ~landmark cur_root lib_name k =
  let waypoints = get_waypoints ~landmark cur_root in
  match Hashtbl.find_opt waypoints lib_name with
  | None -> k ()
  | Some Direct {at} -> File.join @@ cur_root :: at
  | Some Indirect {next; rename} ->
    let cur_root = File.join @@ cur_root :: next in
    let lib_name = Option.value rename ~default:lib_name in
    lookup_waypoint ~landmark cur_root lib_name @@ fun () -> raise Not_found

let rec lookup_waypoint_in_ancestors ~landmark cur_root lib_name =
  let cur_root, _ = File.locate_anchor ~anchor:landmark cur_root in
  lookup_waypoint ~landmark cur_root lib_name @@ fun () ->
  lookup_waypoint_in_ancestors ~landmark (Filename.dirname cur_root) lib_name

let resolver ~strict_checking ~landmark =
  let fast_checker ~cur_root r =
    if strict_checking then
      try ignore @@ lookup_waypoint_in_ancestors ~landmark cur_root @@ Marshal.to_string r; true with _ -> false
    else
      try ignore @@ Marshal.to_string r; true with _ -> false
  and resolver ~cur_root r =
    try Option.some @@ lookup_waypoint_in_ancestors ~landmark cur_root @@ Marshal.to_string r with _ -> None
  in
  Resolver.make ~fast_checker resolver
