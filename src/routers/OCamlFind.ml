open BantorraBasis
open ResultMonad.Syntax
open Bantorra

let findlib_init = lazy begin Findlib.init () end

let get_package_dir pkg =
  Lazy.force findlib_init;
  try
    ret @@ Findlib.package_directory pkg
  with
  | Findlib.No_such_package (pkg, msg) ->
    Router.invalid_router_error ~maker:"OCamlFind.router" "no package named %s: %s" pkg msg
  | Findlib.Package_loop pkg ->
    Router.invalid_router_error ~maker:"OCamlFind.router" "package %s required by itself" pkg

let router ~package_name ~dict =
  let* package_dir = get_package_dir package_name in
  let dict = List.map File.(fun (name, path) -> name, package_dir/path) dict in
  FixedTable.router ~dict
