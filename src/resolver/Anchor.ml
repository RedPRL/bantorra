open Basis

let version = "1.0.0"

type path = string list
type lib_name =
  { name : string
  ; version : string option
  }

type t =
  { name : string option
  ; libraries : (path * lib_name) list
  }

let default = {name = None; libraries = []}

let to_path : Marshal.value -> path = Marshal.to_list Marshal.to_string

(* XXX this does not detect duplicate or useless keys *)
let to_library_ ms =
  match
    List.assoc_opt "name" ms,
    List.assoc_opt "version" ms,
    List.assoc_opt "mount_point" ms
  with
  | Some name, version, Some mount_point ->
    to_path mount_point,
    { name = Marshal.to_string name
    ; version = Option.bind version Marshal.to_ostring
    }
  | _ -> raise Marshal.IllFormed

let to_library =
  function
  | `O ms -> to_library_ ms
  | _ -> raise Marshal.IllFormed

let check_libraries libs =
  let mount_points = List.map (fun (mp, _) -> mp) libs in
  if List.exists ((=) []) mount_points then raise Marshal.IllFormed;
  if Basis.Util.has_duplication mount_points then raise Marshal.IllFormed;
  ()

(* XXX this does not detect duplicate or useless keys *)
let of_yaml_ (ms : (string * Marshal.value) list) : t =
  match
    List.assoc_opt "format" ms,
    List.assoc_opt "name" ms,
    List.assoc_opt "libraries" ms
  with
  | Some (`String format_version), name, libraries when format_version = version ->
    let libraries = Option.fold ~none:[] ~some:(Marshal.to_list to_library) libraries in
    check_libraries libraries;
    { name = Option.bind name Marshal.to_ostring
    ; libraries
    }
  | _ -> raise Marshal.IllFormed

let deserialize : Marshal.value -> t =
  function
  | `O ms -> of_yaml_ ms
  | _ -> raise Marshal.IllFormed

let read archor =
  try deserialize @@ Marshal.read_plain archor with _ -> default (* XXX some warning here *)

let iter_lib_names f {libraries; _} =
  List.iter (fun (_, lib_name) -> f lib_name) libraries

let rec match_prefix nmatched prefix path k =
  match prefix, path with
  | [], _ -> Some (nmatched, k path)
  | _, [] -> None
  | (id :: prefix), (id' :: path) ->
    if id = id' then match_prefix (nmatched + 1) prefix path k else None

let maximum_assoc : (int * 'a) list -> 'a option =
  let max (n0, p0) (n1, p1) = if n0 > n1 then n0, p0 else n1, p1 in
  function
  | [] -> None
  | x :: l -> Some (let _, v = List.fold_left max x l in v)

let dispatch_path {libraries; _} path =
  maximum_assoc begin
    libraries |> List.filter_map @@ fun (mount_point, lib) ->
    match_prefix 0 mount_point path @@ fun path -> lib, path
  end
