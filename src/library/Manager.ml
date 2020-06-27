open BantorraBasis

type t =
  { anchor : string
  ; resolvers : (string, Resolver.t) Hashtbl.t
  ; loaded_libs : (string, Library.t) Hashtbl.t
  }
type library = Library.t
type unitpath = Anchor.unitpath

let check_dep resolvers root =
  Library.iter_deps @@ fun {resolver; res_args} ->
  match Hashtbl.find_opt resolvers resolver with
  | None -> failwith ("Unknown resolver: "^resolver)
  | Some r ->
    if not (Resolver.fast_check r ~cur_root:root res_args) then
      failwith ("Library "^Resolver.dump_args r ~cur_root:root res_args^" could not be found.")

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

let save_state {loaded_libs; _} =
  Hashtbl.iter (fun _ lib -> Library.save_state lib) loaded_libs

let rec_resolver f lm =
  let rec global ~cur_root ({resolver; res_args} : Anchor.lib_ref) =
    let resolver = Hashtbl.find lm.resolvers resolver in
    let lib_root = Resolver.resolve resolver ~cur_root res_args in
    let lib = load_library lm lib_root in
    f ~global lib
  in
  f ~global

let resolve = rec_resolver Library.resolve
let replace_cache = rec_resolver Library.replace_cache
let find_cache_opt = rec_resolver Library.find_cache_opt
