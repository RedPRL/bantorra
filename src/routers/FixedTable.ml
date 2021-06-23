module E = Errors
open BantorraBasis
open ResultMonad.Syntax
open Bantorra

let router ~dict =
  let src = "FixedTable.router" in
  match
    let normalize (n, p) =
      let+ p = File.normalize_dir p in n, p
    in
    let* dict = ResultMonad.map normalize dict in
    let* dict = Util.Hashtbl.of_unique_seq @@ List.to_seq dict in
    let fast_checker ~starting_dir:_ r = try Hashtbl.mem dict @@ Result.get_ok @@ Marshal.to_string r with _ -> false
    and route ~starting_dir:_ arg =
      let src = "FixedTable.route" in
      match
        let* arg = Marshal.to_string arg in
        match Hashtbl.find_opt dict arg with
        | None -> error @@ `NotFound arg
        | Some lib_root -> ret lib_root
      with
      | Error (`NotFound arg) ->
        E.error_invalid_library_msgf ~src "Could not find the library named `%s' in the table" arg
      | Error (`FormatError msg) ->
        E.append_error_invalid_library_msg ~earlier:msg ~src "Could not parse the argument"
      | Ok lib_root -> ret lib_root
    in
    ret @@ Router.make ~fast_checker route
  with
  | Error (`DuplicateKeys key) ->
    E.error_invalid_router_msgf ~src "Duplicate entries `%s' in the table" key
  | Error (`SystemError msg) ->
    E.append_error_invalid_router_msg ~earlier:msg ~src "Could not normalize the paths in the table"
  | Ok router -> ret router
