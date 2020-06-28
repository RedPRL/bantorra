open BantorraBasis
open BantorraBasis.File
module S = BantorraCache.Store

type unitpath = Anchor.unitpath

type t =
  { root : string
  ; anchor : Anchor.t
  ; cache : S.t
  }

let default_cache_subdir = "_cache"

let init ~anchor ~root =
  let anchor = Anchor.read @@ root / anchor in
  let cache_root = root / default_cache_subdir in
  ensure_dir cache_root;
  let cache = S.init ~root:(root / default_cache_subdir) in
  {root; anchor; cache}

let locate_anchor ~anchor ~suffix filepath =
  if not @@ Sys.file_exists filepath then
    invalid_arg @@ "locate_anchor: " ^ filepath ^ " does not exist";
  match Filename.chop_suffix_opt ~suffix @@ Filename.basename filepath with
  | None -> invalid_arg @@ "locate_anchor: " ^ filepath ^ " does not have suffix " ^ suffix
  | Some basename ->
    let root, unitpath = File.locate_anchor ~anchor @@ Filename.dirname filepath in
    root, unitpath @ [basename]

let save_state {cache; _} =
  S.save_state cache

let iter_deps f {anchor; _} = Anchor.iter_deps f anchor

let dispatch_path local ~global lib path =
  match Anchor.dispatch_path lib.anchor path with
  | None -> local lib path
  | Some (lib_name, path) -> global ~cur_root:lib.root lib_name path

(** @param suffix The suffix should include the dot. *)
let resolve_local lib path ~suffix =
  match path with
  | [] -> invalid_arg "to_rel_filepath: empty unit path"
  | path -> lib, File.join (lib.root :: path) ^ suffix

(** Generate the JSON [key] from immediately available metadata. *)
let make_local_key path ~source_digest : Marshal.value =
  `O [ "path", Marshal.of_list Marshal.of_string path
     ; "source_digest", Marshal.of_string source_digest
     ]

let replace_local_cache {cache; _} path ~source_digest value =
  let key = make_local_key path ~source_digest in
  S.replace_item cache ~key ~value

let find_local_cache_opt {cache; _} path ~source_digest ~cache_digest =
  let key = make_local_key path ~source_digest in
  S.find_item_opt cache ~key ~digest:cache_digest

(** @param suffix The suffix should include the dot. *)
let resolve = dispatch_path resolve_local
let replace_cache = dispatch_path replace_local_cache
let find_cache_opt = dispatch_path find_local_cache_opt
