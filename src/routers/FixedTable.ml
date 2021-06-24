module E = Errors
open BantorraBasis
open ResultMonad.Syntax
open Bantorra

let router ~dict =
  let src = "FixedTable.router" in
  match
    let* dict =
      ResultMonad.map
        (fun (n, p) -> let+ p = File.input_absolute_dir p in n, p)
        dict
    in
    Util.Hashtbl.of_unique_seq @@ List.to_seq dict
  with
  | Error (`DuplicateKeys key) ->
    E.error_invalid_router_msgf ~src "Duplicate entries `%s' in the table" key
  | Error (`SystemError msg) ->
    E.append_error_invalid_router_msg ~earlier:msg ~src "Could not normalize the paths in the table"
  | Ok dict ->
    ret @@ Router.make @@ fun ~starting_dir:_ ~arg ->
    let src = "FixedTable.route" in
    match
      let* router_argument = Marshal.to_string arg in
      match Hashtbl.find_opt dict router_argument with
      | None -> error @@ `NotFound router_argument
      | Some lib_root -> ret lib_root
    with
    | Error (`NotFound arg) ->
      E.error_invalid_library_msgf ~src "Could not find the library named `%s' in the table" arg
    | Error (`FormatError msg) ->
      E.append_error_invalid_library_msg ~earlier:msg ~src "Could not parse the argument"
    | Ok lib_root -> ret lib_root
