open BantorraBasis
open BantorraBasis.File
open Bantorra

let version = "1.0.0"

type info = Direct of {at: string list} | Indirect of {next: string list; rename: string option}

type t = (string, info) Hashtbl.t

module M =
struct
  let to_info : Marshal.value -> info =
    function
    | `O ["at", at] ->
      Direct {at = Marshal.(to_list to_string at)}
    | `O ["next", next] ->
      Indirect {next = Marshal.(to_list to_string next); rename = None}
    | `O ["rename", `String rename; "next", next]
    | `O ["next", next; "rename", `String rename] ->
      Indirect {next = Marshal.(to_list to_string next); rename = Some rename}
    | _ -> raise Marshal.IllFormed
end

let deserialize : Marshal.value -> t =
  function
  | `O ["format", `String v; "waypoints", `O dict] when v = version ->
    Hashtbl.of_seq @@ Seq.map (fun (n, i) -> n, M.to_info i) @@ List.to_seq dict
  | _ -> raise Marshal.IllFormed

(* XXX errors are not handled *)
let rec lookup_waypoint_ ~landmark cur_root lib_name k =
  let waypoints = deserialize @@ Marshal.read_plain @@ cur_root / landmark in
  match Hashtbl.find_opt waypoints lib_name with
  | None -> k ()
  | Some Direct {at} -> File.join @@ cur_root :: at
  | Some Indirect {next; rename} ->
    let cur_root = File.join @@ cur_root :: next in
    let lib_name = Option.value rename ~default:lib_name in
    lookup_waypoint_ ~landmark cur_root lib_name @@ fun () -> raise Not_found

let rec lookup_waypoint ~landmark cur_root lib_name =
  let cur_root, _ = File.locate_anchor ~anchor:landmark cur_root in
  lookup_waypoint_ ~landmark cur_root lib_name @@ fun () ->
  lookup_waypoint ~landmark (Filename.dirname cur_root) lib_name

let resolver ~strict_checking ~landmark =
  let fast_checker ~cur_root r =
    if strict_checking then
      try ignore @@ lookup_waypoint ~landmark cur_root @@ Marshal.to_string r; true with _ -> false
    else
      try ignore @@ Marshal.to_string r; true with _ -> false
  and resolver ~cur_root r =
    try Option.some @@ lookup_waypoint ~landmark cur_root @@ Marshal.to_string r with _ -> None
  in
  Resolver.make ~fast_checker resolver
