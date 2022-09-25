module E = Error

type t =
  { version : string
  ; anchor : string
  ; router : Router.t
  ; lock : Mutex.t
  ; loaded_libs : (FilePath.t, Library.t) Hashtbl.t
  }
type path = UnitPath.t
type library = Library.t

let init ~version ~anchor router =
  let loaded_libs = Hashtbl.create 10 in
  {version; anchor; router; lock = Mutex.create (); loaded_libs}

let find_cache lm = Hashtbl.find_opt lm.loaded_libs

let cache_library lm lib =
  let lib_root = Library.root lib in
  Hashtbl.replace lm.loaded_libs lib_root lib

let load_library_from_root lm lib_root =
  Utils.with_mutex lm.lock @@ fun () ->
  let lib = Library.load_from_root ~version:lm.version ~find_cache:(find_cache lm) ~anchor:lm.anchor lib_root in
  cache_library lm lib; lib

let load_library_from_route lm ?starting_dir route =
  let lib_root = Router.run ?starting_dir @@ fun () -> lm.router route in
  load_library_from_root lm lib_root

let load_library_from_route_with_cwd lm route  =
  load_library_from_route lm ~starting_dir:(File.get_cwd ()) route

let load_library_from_dir lm dir =
  Utils.with_mutex lm.lock @@ fun () ->
  let lib, path_opt = Library.load_from_dir ~version:lm.version ~find_cache:(find_cache lm) ~anchor:lm.anchor dir in
  cache_library lm lib; lib, path_opt

let load_library_from_cwd lm =
  load_library_from_dir lm @@ File.get_cwd ()

let load_library_from_unit lm filepath ~suffix =
  Utils.with_mutex lm.lock @@ fun () ->
  let lib, path_opt = Library.load_from_unit ~version:lm.version ~find_cache:(find_cache lm) ~anchor:lm.anchor filepath ~suffix in
  cache_library lm lib; lib, path_opt

let library_root = Library.root

let resolve lm ?(max_depth=100) =
  let rec global ~depth ?starting_dir route path ~suffix =
    E.tracef "Resolving library via route %a" (Json_repr.pp (module Json_repr.Ezjsonm)) route @@ fun () ->
    if depth > max_depth then
      E.fatalf `InvalidLibrary "Library resolution stack overflow (max depth = %i)." max_depth
    else
      let lib = load_library_from_route lm ?starting_dir route in
      Library.resolve ~depth ~global lib path ~suffix
  in
  Library.resolve ~depth:0 ~global