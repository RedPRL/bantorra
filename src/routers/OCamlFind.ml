module E = Errors
open BantorraBasis
open ResultMonad.Syntax

let findlib_init = lazy begin Findlib.init () end

let get_package_dir pkg =
  let src = "OCamlFind get_package_dir" in
  Lazy.force findlib_init;
  try
    ret @@ Findlib.package_directory pkg
  with
  | Findlib.No_such_package (pkg, msg) ->
    E.error_invalid_router_msgf ~src "No package named %s: %s" pkg msg
  | Findlib.Package_loop pkg ->
    E.error_invalid_router_msgf ~src "Package %s required by itself" pkg

let router ~package_name ~dict =
  let* package_dir = get_package_dir package_name in
  let dict = List.map File.(fun (name, path) -> name, package_dir/path) dict in
  FixedTable.router ~dict
