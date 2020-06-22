open BantorraBasis
open BantorraBasis.File
module D = BantorraCache.Database

type path = string list

type t =
  { root : string
  ; anchor : Anchor.t
  ; cache : D.t
  }

let default_cache_subdir = "_cache"

let init ~anchor ~root =
  let anchor = Anchor.read @@ root / anchor
  and cache = D.init ~root:(root / default_cache_subdir) in
  {root; anchor; cache}

let save_state {cache; _} =
  D.save_state cache

let locate_anchor ~anchor ~suffix filepath =
  if not @@ Sys.file_exists filepath then
    invalid_arg @@ "init_from_filepath: " ^ filepath ^ " does not exist";
  match Filename.chop_suffix_opt ~suffix @@ Filename.basename filepath with
  | None -> invalid_arg @@ "init_from_filepath: " ^ filepath ^ " does not have suffix " ^ suffix
  | Some basename ->
    let rec find_root cwd unitpath_acc =
      if is_existing_and_regular anchor then
        cwd, unitpath_acc
      else
        let parent = Filename.dirname cwd in
        if parent = cwd then
          raise Not_found
        else begin
          Sys.chdir parent;
          find_root parent @@ Filename.basename cwd :: unitpath_acc
        end
    in
    protect_cwd @@ fun _ ->
    Sys.chdir @@ Filename.dirname filepath;
    find_root (Sys.getcwd ()) [basename]

let iter_deps f {anchor; _} = Anchor.iter_lib_names f anchor

let dispatch_path local ~global lib path =
  match Anchor.dispatch_path lib.anchor path with
  | None -> local lib path
  | Some (lib_name, path) -> global lib_name path

(** @param suffix The suffix should include the dot. *)
let to_local_filepath {root; _} path ~suffix =
  match path with
  | [] -> invalid_arg "to_rel_filepath: empty unit path"
  | path -> root / String.concat Filename.dir_sep path ^ suffix

(** Generate the JSON [key] from immediately available metadata. *)
let make_local_key path ~source_digest : Marshal.value =
  `O [ "path", `A (List.map (fun s -> `String s) path)
     ; "source_digest", `String source_digest
     ]

let replace_local_cache {cache; _} path ~source_digest value =
  let key = make_local_key path ~source_digest in
  D.replace_item cache ~key ~value

let find_local_cache_opt {cache; _} path ~source_digest ~cache_digest =
  let key = make_local_key path ~source_digest in
  D.find_item_opt cache ~key ~digest:cache_digest

(** @param suffix The suffix should include the dot. *)
let to_filepath = dispatch_path to_local_filepath
let replace_cache = dispatch_path replace_local_cache
let find_cache_opt = dispatch_path find_local_cache_opt
