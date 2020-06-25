open BantorraBasis.File

let findlib_init = lazy begin Findlib.init () end

let get_package_dir pkg =
  Lazy.force findlib_init;
  Findlib.package_directory pkg

let resolver ~package_name ~dict =
  let package_dir = get_package_dir package_name in
  let dict = List.map (fun (name, path) -> name, package_dir/path) dict in
  Const.resolver ~dict
