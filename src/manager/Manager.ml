open BantorraLibrary

type t =
  { anchor : string
  ; cur_lib : Library.t
  ; config : Config.t
  ; loaded_libs : (string, Library.t) Hashtbl.t
  }
type path = string list

let check_dep config =
  Library.iter_deps @@ fun dep ->
  if not @@ Config.mem_libs config dep then
    (* XXX better error message with version *)
    failwith ("Library "^dep.name^" with a correct version cannot be found.")

let locate_anchor_and_init ~app_name ~anchor ~suffix path =
  let config = Config.init ~app_name in
  let cur_lib, path = Library.locate_anchor_and_init ~anchor ~suffix path in
  check_dep config cur_lib;
  {anchor; cur_lib; config; loaded_libs = Hashtbl.create @@ Config.length_libs config}, path

let rec_resolver f lm =
  let rec global name =
    let lib_root = Config.find_libs lm.config name in
    let lib =
      match Hashtbl.find_opt lm.loaded_libs lib_root with
      | Some lib -> lib
      | None ->
        let lib = Library.init ~root:lib_root ~anchor:lm.anchor in
        check_dep lm.config lib;
        Hashtbl.replace lm.loaded_libs lib_root lib;
        lib
    in
    f ~global lib
  in
  f ~global lm.cur_lib

let replace_cache = rec_resolver Library.replace_cache
let find_cache_opt = rec_resolver Library.find_cache_opt
