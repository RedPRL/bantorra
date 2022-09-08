open BantorraBasis
module E = Error

type route = Json_repr.ezjsonm
type t = ?hop_limit:int -> lib_root:File.path -> route -> File.path

let fix (f : t -> t) ?hop_limit ~lib_root route =
  let rec go ?(hop_limit=10) ~lib_root route =
    if hop_limit <= 0 then
      E.fatalf `InvalidLibrary "Exceeded hop limit (%d)" hop_limit
    else
      f go ~hop_limit:(hop_limit-1) ~lib_root route
  in
  f go ?hop_limit ~lib_root route
