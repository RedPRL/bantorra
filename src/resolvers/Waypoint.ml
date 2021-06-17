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
    let waypoints = deserialize @@ Marshal.read_json @@ root / landmark in
    Hashtbl.replace cache root waypoints;
    waypoints

let clear_cached_landmarks () =
  Hashtbl.clear cache

(* XXX errors are not handled *)
let rec lookup_waypoint ~landmark current_root lib_name k =
  let waypoints = get_waypoints ~landmark current_root in
  match Hashtbl.find_opt waypoints lib_name with
  | None -> k ()
  | Some Direct {at} -> File.normalize_dir @@ File.join @@ current_root :: at
  | Some Indirect {next; rename} ->
    let current_root = File.join @@ current_root :: next in
    let lib_name = Option.value ~default:lib_name rename in
    lookup_waypoint ~landmark current_root lib_name @@ fun () -> raise Not_found

let rec lookup_waypoint_in_ancestors ~landmark current_root lib_name =
  let current_root, _ = File.locate_anchor ~anchor:landmark current_root in
  lookup_waypoint ~landmark current_root lib_name @@ fun () ->
  match parent_of_normalized_dir current_root with
  | None -> raise Not_found
  | Some parent -> lookup_waypoint_in_ancestors ~landmark parent lib_name

let resolver ?(eager_resolution=false) ~landmark =
  let fast_checker ~current_root arg =
    if eager_resolution then
      try ignore @@ lookup_waypoint_in_ancestors ~landmark current_root @@ Marshal.to_string arg; true with _ -> false
    else
      try ignore @@ Marshal.to_string arg; true with _ -> false
  and resolver ~current_root arg =
    try Option.some @@ lookup_waypoint_in_ancestors ~landmark current_root @@ Marshal.to_string arg with _ -> None
  in
  Resolver.make ~fast_checker resolver
