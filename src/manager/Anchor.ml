open BantorraBasis
open ResultMonad.Syntax

let version = "1.0.0"

type unitpath = string list
type router_name = string
type router_argument = Router.router_argument

type t =
  { routes : (unitpath, router_name * router_argument) Hashtbl.t
  ; cache : (unitpath, (router_name * router_argument * unitpath) option) Hashtbl.t
  }

module M =
struct
  let to_path = Marshal.(to_list to_string)

  let to_route v =
    Marshal.parse_object ~required:["mount_point"; "router"] ~optional:["router_argument"] v >>=
    function
    | ["mount_point", mount_point; "router", router], ["router_argument", router_argument] ->
      let+ router = Marshal.to_string router
      and+ prefix = to_path mount_point
      in
      prefix, (router, router_argument)
    | _ -> assert false
end

let deserialize : Marshal.value -> (t, _) result =
  let src = "Anchor.deserialize" in
  let cache = Hashtbl.create 10 in
  fun v ->
    Marshal.parse_object_or_null ~required:["format"] ~optional:["routes"] v >>=
    function
    | None -> ret {routes = Hashtbl.create 0; cache}
    | Some (["format", format], ["routes", routes]) ->
      let* format = Marshal.to_string format in
      if format <> version then
        Errors.error_format_msgf ~src "Format version `%s' is not supported (only version `%s' is supported)" format version
      else begin
        let* routes = Option.value ~default:[] <$> Marshal.to_olist M.to_route routes in
        match Util.Hashtbl.of_unique_seq @@ List.to_seq routes with
        | Error (`DuplicateKeys k) ->
          Errors.error_format_msgf ~src "Multiple libraries mounted at %a" Util.pp_unitpath k
        | Ok routes -> ret {routes; cache}
      end
    | _ -> assert false

let read anchor = Marshal.read_json anchor >>= deserialize

let iter_routes f {routes; _} =
  Hashtbl.to_seq routes |>
  ResultMonad.iter_seq (fun (_, (router, router_argument)) -> f ~router ~router_argument)

let match_prefix unitpath prefix k =
  let rec loop unitpath prefix acc =
    match unitpath, prefix with
    | _, [] -> Some (acc, k unitpath)
    | [], _ -> None
    | (id :: unitpath), (id' :: prefix) ->
      if String.equal id id' then loop unitpath prefix (acc+1) else None
  in loop unitpath prefix 0

let match_route unitpath (mount_point, (router, router_argument)) =
  match_prefix mount_point unitpath @@ fun unitpath -> router, router_argument, unitpath

let max_match x y =
  match x, y with
  | Some (n0, _), (n1, _) when (n0 : int) >= n1 -> x
  | _ -> Some y

let dispatch_path_without_cache {routes; _} unitpath =
  let matched = Seq.filter_map (match_route unitpath) @@ Hashtbl.to_seq routes in
  Option.map snd @@ Seq.fold_left max_match None matched

let dispatch_path anchor unitpath =
  match Hashtbl.find_opt anchor.cache unitpath with
  | Some ref -> ref
  | None ->
    let ref = dispatch_path_without_cache anchor unitpath in
    Hashtbl.replace anchor.cache unitpath ref;
    ref

let path_is_local anchor unitpath =
  Option.is_none @@ dispatch_path anchor unitpath
