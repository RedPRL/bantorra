open BantorraBasis
open ResultMonad.Syntax
open Bantorra

let router =
  let route ~starting_dir arg =
    match
      let* path = Marshal.to_string arg in
      File.(normalize_dir @@ starting_dir/path)
    with
    | Error (`FormatError msg | `SystemError msg) -> Router.library_load_error "Direct.route: %s" msg
    | Ok dir -> ret dir
  in
  Router.make route
