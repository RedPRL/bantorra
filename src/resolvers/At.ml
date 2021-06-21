open BantorraBasis
open Bantorra

let resolver =
  let resolver ~current_root arg =
    Some (File.normalize_dir @@ File.join @@ current_root :: Marshal.(to_list to_string) arg)
  in
  Resolver.make resolver
