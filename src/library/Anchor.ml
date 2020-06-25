open BantorraBasis

let version = "1.0.0"

type unitpath = string list
type res_args = Marshal.value
type lib_ref =
  { resolver : string
  ; res_args : res_args
  }

type t =
  { deps : (unitpath * lib_ref) list
  }

let default = {deps = []}

let check_deps libs =
  let mount_points = List.map (fun (mp, _) -> mp) libs in
  if List.exists ((=) []) mount_points then raise Marshal.IllFormed;
  if Util.has_duplication mount_points then raise Marshal.IllFormed;
  ()

module M =
struct
  let to_path : Marshal.value -> unitpath = Marshal.to_list Marshal.to_string

  (* XXX this does not detect duplicate or useless keys *)
  let to_dep_ ms =
    match
      List.assoc_opt "resolver" ms,
      List.assoc_opt "res_args" ms,
      List.assoc_opt "mount_point" ms
    with
    | Some resolver, Some res_args, Some mount_point ->
      to_path mount_point,
      { resolver = Marshal.to_string resolver
      ; res_args
      }
    | _ -> raise Marshal.IllFormed

  let to_dep =
    function
    | `O ms -> to_dep_ ms
    | _ -> raise Marshal.IllFormed
end

let deserialize : Marshal.value -> t =
  function
  | `O ms ->
    begin
      (* XXX this does not detect duplicate or useless keys *)
      match
        List.assoc_opt "format" ms,
        List.assoc_opt "deps" ms
      with
      | Some (`String format_version), deps when format_version = version ->
        let deps = Option.fold ~none:[] ~some:(Marshal.to_list M.to_dep) deps in
        check_deps deps;
        { deps }
      | _ -> raise Marshal.IllFormed
    end
  | _ -> raise Marshal.IllFormed

let read archor =
  try deserialize @@ Marshal.read_plain archor with _ -> default (* XXX some warning here *)

let iter_deps f {deps; _} =
  List.iter (fun (_, lib_name) -> f lib_name) deps

let rec match_prefix nmatched prefix unitpath k =
  match prefix, unitpath with
  | [], _ -> Some (nmatched, k unitpath)
  | _, [] -> None
  | (id :: prefix), (id' :: unitpath) ->
    if id = id' then match_prefix (nmatched + 1) prefix unitpath k else None

let maximum_assoc : (int * 'a) list -> 'a option =
  let max (n0, p0) (n1, p1) = if n0 > n1 then n0, p0 else n1, p1 in
  function
  | [] -> None
  | x :: l -> Some (let _, v = List.fold_left max x l in v)

let dispatch_path {deps; _} unitpath =
  maximum_assoc begin
    deps |> List.filter_map @@ fun (mount_point, lib) ->
    match_prefix 0 mount_point unitpath @@ fun unitpath -> lib, unitpath
  end
