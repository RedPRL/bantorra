open BantorraBasis
open Bantorra

let resolver ~dict =
  let dict = Util.Hashtbl.of_unique_seq @@ Seq.map (fun (n, p) -> n, File.normalize_dir p) @@ List.to_seq dict in
  let fast_checker ~current_root:_ r = try Hashtbl.mem dict @@ Marshal.to_string r with _ -> false
  and resolver ~current_root:_ r = try Hashtbl.find_opt dict @@ Marshal.to_string r with _ -> None
  in
  Resolver.make ~fast_checker resolver
