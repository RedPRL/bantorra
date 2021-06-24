module E = Errors
open BantorraBasis

type argument = Marshal.value
type t =
  { fast_checker: starting_dir:File.filepath -> arg:argument -> bool
  ; router: starting_dir:File.filepath -> arg:argument -> (File.filepath, [`InvalidLibrary of string]) result
  }

let make ?fast_checker router =
  let fast_checker = Option.value fast_checker
      ~default:(fun ~starting_dir ~arg -> Result.is_ok @@ router ~starting_dir ~arg)
  in
  {fast_checker; router}

let route {router; _} ~starting_dir ~arg =
  E.open_error_invalid_library @@ router ~starting_dir ~arg
let fast_check {fast_checker; _} = fast_checker
