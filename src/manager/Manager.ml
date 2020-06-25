open BantorraLibrary

type t =
  { anchor : string
  ; cur_lib : Library.t
  ; resolvers : (string, Resolver.t) Hashtbl.t
  ; loaded_libs : (string, Library.t) Hashtbl.t
  }
type path = string list

let check_dep resolvers root =
  Library.iter_deps @@ fun {resolver; info} ->
  match Hashtbl.find_opt resolvers resolver with
  | None -> failwith ("Unknown resolver: "^resolver)
  | Some r ->
    if not (Resolver.fast_check r ~cur_root:root info) then
      failwith ("Library "^Resolver.dump_info r ~cur_root:root info^" could not be found.")

let init ~resolvers ~anchor ~root =
  let cur_lib = Library.init ~anchor ~root in
  let resolvers = Hashtbl.of_seq @@ List.to_seq resolvers in
  check_dep resolvers root cur_lib;
  let loaded_libs = Hashtbl.create 10 in
  Hashtbl.replace loaded_libs root cur_lib;
  {anchor; cur_lib; resolvers; loaded_libs}

let save_state {loaded_libs; _} =
  Hashtbl.iter (fun _ lib -> Library.save_state lib) loaded_libs

let rec_resolver f lm =
  let rec global ~cur_root ({resolver; info} : Anchor.lib_ref) =
    let resolver = Hashtbl.find lm.resolvers resolver in
    let lib_root = Resolver.resolve resolver ~cur_root info in
    let lib =
      match Hashtbl.find_opt lm.loaded_libs lib_root with
      | Some lib -> lib
      | None ->
        let lib = Library.init ~root:lib_root ~anchor:lm.anchor in
        check_dep lm.resolvers lib_root lib;
        Hashtbl.replace lm.loaded_libs lib_root lib;
        lib
    in
    f ~global lib
  in
  f ~global lm.cur_lib

let to_filepath = rec_resolver Library.to_filepath
let replace_cache = rec_resolver Library.replace_cache
let find_cache_opt = rec_resolver Library.find_cache_opt
