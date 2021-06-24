module E = Errors
open BantorraBasis
open ResultMonad.Syntax
open Bantorra

let router =
  let route ~starting_dir ~arg =
    let src = "Direct.route" in
    match
      Marshal.to_string arg >>= File.input_absolute_dir ~starting_dir
    with
    | Error (`FormatError msg | `SystemError msg) ->
      E.append_error_invalid_library_msg ~earlier:msg ~src "Could not find the library"
    | Ok dir -> ret dir
  in
  Router.make route
