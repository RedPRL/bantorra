open BantorraBasis

let version = "1.0.0"

type unitpath = string list
type res_args = Resolver.res_args
type lib_ref =
  { resolver : string
  ; res_args : res_args
  }

type t =
  { deps : (unitpath, lib_ref) Hashtbl.t
  }

let default () = {deps = Hashtbl.create 1}

let check_deps libs =
  if Hashtbl.mem libs [] then raise Marshal.IllFormed

module M =
struct
  let to_path : Marshal.value -> unitpath = Marshal.to_list Marshal.to_string

  let to_dep_ ms =
    match List.sort Stdlib.compare ms with
    | ["mount_point", mount_point; "res_args", res_args; "resolver", resolver] ->
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
      match List.sort Stdlib.compare ms with
      | ["format", `String format_version] when format_version = version ->
        { deps = Hashtbl.create 0 }
      | ["deps", deps; "format", `String format_version] when format_version = version ->
        let deps = Util.Hashtbl.of_unique_seq @@ List.to_seq @@ Marshal.to_list M.to_dep deps in
        check_deps deps;
        { deps }
      | _ -> raise Marshal.IllFormed
    end
  | _ -> raise Marshal.IllFormed

let read archor =
  try deserialize @@ Marshal.read_plain archor with _ -> default () (* XXX some warning here *)

let iter_deps f {deps; _} =
  Hashtbl.iter (fun _ lib_name -> f lib_name) deps

let rec match_prefix nmatched prefix unitpath k =
  match prefix, unitpath with
  | [], _ -> Some (nmatched, k unitpath)
  | _, [] -> None
  | (id :: prefix), (id' :: unitpath) ->
    if id = id' then match_prefix (nmatched + 1) prefix unitpath k else None

let max_match x y =
  match x, y with
  | Some (n0, _), (n1, _) when n0 >= n1 -> x
  | _ -> Some y

let dispatch_path {deps; _} unitpath =
  Option.map (fun (_, r) -> r) @@ Seq.fold_left max_match None begin
    Hashtbl.to_seq deps |> Seq.filter_map @@ fun (mount_point, lib) ->
    match_prefix 0 mount_point unitpath @@ fun unitpath -> lib, unitpath
  end
