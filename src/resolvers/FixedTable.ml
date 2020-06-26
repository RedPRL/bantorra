open BantorraBasis
open Bantorra

let resolver ~dict =
  let lib_names = List.map (fun (n, _) -> n) dict in
  if Util.has_duplication lib_names then failwith "Duplicate library names in the dict";
  let dict = Hashtbl.of_seq @@ Seq.map (fun (n, p) -> n, File.normalize_dir p) @@ List.to_seq dict in
  let fast_checker ~cur_root:_ r = try Hashtbl.mem dict @@ Marshal.to_string r with _ -> false
  and resolver ~cur_root:_ r = try Hashtbl.find_opt dict @@ Marshal.to_string r with _ -> None
  in
  Resolver.make ~fast_checker resolver
