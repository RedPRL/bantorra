open BantorraBasis

type t =
  { anchor : string
  ; resolvers : (string, Resolver.t) Hashtbl.t
  ; loaded_libs : (string, Library.t) Hashtbl.t
  }
type library = Library.t
type filepath = string
type unitpath = Anchor.unitpath

let check_dep resolvers root =
  Library.iter_deps @@ fun {resolver; resolver_argument} ->
  match Hashtbl.find_opt resolvers resolver with
  | None -> failwith ("Unknown resolver: "^resolver)
  | Some r ->
    if not (Resolver.fast_check r ~current_root:root resolver_argument) then
      failwith ("Library "^Resolver.dump_argument r ~current_root:root resolver_argument^" could not be found.")

let init ~resolvers ~anchor =
  let resolvers = Util.Hashtbl.of_unique_seq @@ List.to_seq resolvers in
  let loaded_libs = Hashtbl.create 10 in
  {anchor; resolvers; loaded_libs}

let load_library lm lib_root =
  match Hashtbl.find_opt lm.loaded_libs lib_root with
  | Some lib -> lib
  | None ->
    let lib = Library.init ~root:lib_root ~anchor:lm.anchor in
    check_dep lm.resolvers lib_root lib;
    Hashtbl.replace lm.loaded_libs lib_root lib;
    lib

let locate_anchor = Library.locate_anchor

let rec_resolver f lm =
  let rec global ~current_root ({resolver; resolver_argument} : Anchor.lib_ref) =
    let resolver = Hashtbl.find lm.resolvers resolver in
    let lib_root = Resolver.resolve resolver ~current_root resolver_argument in
    let lib = load_library lm lib_root in
    f ~global lib
  in
  f ~global

let to_unitpath = rec_resolver Library.to_unitpath
let to_filepath = rec_resolver Library.to_filepath
