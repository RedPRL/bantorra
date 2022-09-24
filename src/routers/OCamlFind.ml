open BantorraBasis
module E = Error

let findlib_init = lazy begin Findlib.init () end

let get_package_dir pkg =
  Lazy.force findlib_init;
  try
    FilePath.of_string @@ Findlib.package_directory pkg
  with
  | Findlib.No_such_package (pkg, msg) ->
    E.fatalf `System "No package named %s: %s" pkg msg
  | Findlib.Package_loop pkg ->
    E.fatalf `System "Package %s required by itself" pkg
