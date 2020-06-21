type t =
  { cur_lib : Library.t
  ; global_libs : (Anchor.lib_name, Library.t) Hashtbl.t
  }
type path = string list

(* TODO global library mapping *)
let locate_anchor_and_init ~anchor_path ~suffix path =
  let cur_lib, path = Library.locate_anchor_and_init ~anchor_path ~suffix path
  and global_libs = Hashtbl.create 0 in
  Library.iter_deps (fun _ -> failwith "No global libraries") cur_lib;
  { cur_lib
  ; global_libs
  },
  path

let rec_resolver f lm =
  let rec global name =
    f ~global @@ Hashtbl.find lm.global_libs name
  in
  f ~global lm.cur_lib

let replace_cache = rec_resolver Library.replace_cache
let find_cache_opt = rec_resolver Library.find_cache_opt
