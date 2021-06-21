open BantorraBasis
open ResultMonad.Syntax
open Bantorra

let router ~dict =
  match
    let normalize (n, p) =
      let+ p = File.normalize_dir p in n, p
    in
    let* dict = ResultMonad.map normalize dict in
    let* dict = Util.Hashtbl.of_unique_seq @@ List.to_seq dict in
    let fast_checker ~starting_dir:_ r = try Hashtbl.mem dict @@ Result.get_ok @@ Marshal.to_string r with _ -> false
    and route ~starting_dir:_ arg =
      match
        let* arg = Marshal.to_string arg in
        match Hashtbl.find_opt dict arg with
        | None -> error @@ `NotFound arg
        | Some lib_root -> ret lib_root
      with
      | Error (`NotFound arg) ->
        Router.library_load_error "FixedTable.route: could not find the library %s" arg
      | Error (`FormatError msg) ->
        Router.library_load_error "FixedTable.route: %s" msg
      | Ok lib_root -> ret lib_root
    in
    ret @@ Router.make ~fast_checker route
  with
  | Error (`DuplicateKeys key) -> Router.invalid_router_error ~maker:"FixedTable.router" "duplicate entries %s" key
  | Error (`SystemError msg) -> Router.invalid_router_error ~maker:"FixedTable.router" "%s" msg
  | Ok router -> ret router
