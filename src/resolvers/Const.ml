open BantorraBasis
open Bantorra

let resolver ~dict =
  let dict = Hashtbl.of_seq @@ List.to_seq dict in
  let fast_checker ~cur_root:_ r = try Hashtbl.mem dict @@ Marshal.to_string r with _ -> false
  and resolver ~cur_root:_ r = try Hashtbl.find_opt dict @@ Marshal.to_string r with _ -> None
  in
  Resolver.make ~fast_checker resolver
