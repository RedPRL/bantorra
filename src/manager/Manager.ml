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
  Library.iter_routes @@ fun {router; router_argument} ->
  match Hashtbl.find_opt routers router with
  | None -> Router.library_load_error "router %s not found" router
  | Some r ->
    if Router.fast_check r ~starting_dir:root router_argument then
      ret ()
    else
      Router.library_load_error "router %s: %s" router @@
      Router.dump_argument r ~starting_dir:root router_argument

let init ~anchor ~routers =
  match Util.Hashtbl.of_unique_seq @@ List.to_seq routers with
  | Error (`DuplicateKeys key) ->
    Printf.kprintf (fun msg -> error @@ `InvalidRoutingTable msg)
      "multiple routers named %s" key
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

let load_library_from_route lm Anchor.{router; router_argument} =
  match Hashtbl.find_opt lm.routers router with
  | None -> Router.library_load_error "router %s not found" router
  | Some loaded_router ->
    let starting_dir = Sys.getcwd () in
    let* lib_root = Router.route loaded_router ~starting_dir router_argument in
    load_library_from_root lm lib_root

let load_library_from_dir lm dir =
  let* lib, unitpath_opt = Library.load_from_dir ~find_cache:(find_cache lm) ~anchor:lm.anchor dir in
  let* () = check_and_cache_library lm lib in
  ret (lib, unitpath_opt)

let load_library_from_cwd lm =
  load_library_from_dir lm @@ Sys.getcwd ()

let load_library_from_unit lm ~suffix filepath =
  let* lib, unitpath_opt = Library.load_from_unit ~find_cache:(find_cache lm) ~anchor:lm.anchor ~suffix filepath in
  let* () = check_and_cache_library lm lib in
  ret (lib, unitpath_opt)

let resolve lm =
  let rec global ~starting_dir Anchor.{router; router_argument} unitpath ~suffix =
    match
      let loaded_router = Hashtbl.find lm.routers router (* this must succeed due to [check_dep] *) in
      let* lib_root = Router.route loaded_router ~starting_dir router_argument in
      let* lib = load_library_from_root lm lib_root in
      Library.resolve ~global lib unitpath ~suffix
    with
    | Error (`UnitNotFound e | `InvalidLibrary e) ->
      Library.unit_resolve_error "router %s on %s: %s" router (Util.string_of_unitpath unitpath) e
    | Ok res -> ret res
  in
  Library.resolve ~global
