module E = Errors
open BantorraBasis
open ResultMonad.Syntax

type t =
  { anchor : string
  ; routers : (string, Router.t) Hashtbl.t
  ; loaded_libs : (string, Library.t) Hashtbl.t
  }
type library = Library.t
type unitpath = Anchor.unitpath

let check_dep routers root =
  let src = "Manager.check_dep" in
  Library.iter_routes @@ fun ~router ~router_argument ->
  match Hashtbl.find_opt routers router with
  | None -> E.error_invalid_library_msgf ~src "Could not find the router named `%s'" router
  | Some r ->
    if Router.fast_check r ~starting_dir:root router_argument then
      ret ()
    else
      E.error_invalid_library_msgf ~src
        "The fast checking failed for the route with router = `%s' and router_argument = `%a'"
        router Marshal.dump router_argument

let init ~anchor ~routers =
  let src = "Manager.init" in
  match Util.Hashtbl.of_unique_seq @@ List.to_seq routers with
  | Error (`DuplicateKeys key) ->
    E.error_invalid_router_msgf ~src "Multiple routers named %s" key
  | Ok routers ->
    let loaded_libs = Hashtbl.create 10 in
    ret {anchor; routers; loaded_libs}

let find_cache lm = Hashtbl.find_opt lm.loaded_libs

let check_and_cache_library lm lib =
  let lib_root = Library.root lib in
  let* () = check_dep lm.routers lib_root lib in
  Hashtbl.replace lm.loaded_libs lib_root lib;
  ret ()

let load_library_from_root lm lib_root =
  let* lib = Library.load_from_root ~find_cache:(find_cache lm) ~anchor:lm.anchor lib_root in
  let* () = check_and_cache_library lm lib in
  ret lib

let load_library_from_route lm ~router ~router_argument ~starting_dir =
  let src = "Manager.load_library_from_route" in
  match Hashtbl.find_opt lm.routers router with
  | None -> E.error_invalid_library_msgf ~src "Router `%s' not found" router
  | Some loaded_router ->
    let* lib_root = Router.route loaded_router ~starting_dir router_argument in
    load_library_from_root lm lib_root

let load_library_from_route_with_cwd lm ~router ~router_argument  =
  load_library_from_route lm  ~router_argument ~router ~starting_dir:(File.getcwd ())

let load_library_from_dir lm dir =
  let* lib, unitpath_opt = Library.load_from_dir ~find_cache:(find_cache lm) ~anchor:lm.anchor dir in
  let* () = check_and_cache_library lm lib in
  ret (lib, unitpath_opt)

let load_library_from_cwd lm =
  load_library_from_dir lm @@ File.getcwd ()

let load_library_from_unit lm filepath ~suffix =
  let* lib, unitpath_opt = Library.load_from_unit ~find_cache:(find_cache lm) ~anchor:lm.anchor filepath ~suffix in
  let* () = check_and_cache_library lm lib in
  ret (lib, unitpath_opt)

let resolve lm =
  let src = "Manager.resolve" in
  let rec global ~router ~router_argument ~starting_dir unitpath ~suffix =
    match
      let* lib = load_library_from_route lm ~starting_dir ~router ~router_argument in
      Library.resolve ~global lib unitpath ~suffix
    with
    | Error (`UnitNotFound msg | `InvalidLibrary msg) ->
      E.append_error_unit_not_found_msgf ~earlier:msg ~src
        "Could not find %a via the route with router = `%s' and router_argument = `%a'"
        Util.pp_unitpath unitpath router Marshal.dump router_argument
    | Ok res -> ret res
  in
  Library.resolve ~global
