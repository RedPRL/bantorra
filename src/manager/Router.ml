module E = Errors
open BantorraBasis

type router_argument = Marshal.value
type t =
  { fast_checker: starting_dir:File.filepath -> router_argument -> bool
  ; router: starting_dir:File.filepath -> router_argument -> (File.filepath, [`InvalidLibrary of string]) result
  }

let make ?fast_checker router =
  let fast_checker = Option.value fast_checker
      ~default:(fun ~starting_dir l -> Result.is_ok @@ router ~starting_dir l)
  in
  {fast_checker; router}

let route {router; _} ~starting_dir router_argument =
  E.open_error_invalid_library @@ router ~starting_dir router_argument
let route_opt {router; _} ~starting_dir router_argument =
  Result.to_option @@ router ~starting_dir router_argument
let fast_check {fast_checker; _} = fast_checker
