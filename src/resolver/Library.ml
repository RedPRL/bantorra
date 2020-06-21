open Basis
open Basis.File
module D = Cache.Database

type path = string list

type t =
  { root : string
  ; anchor_path : string
  ; anchor : Anchor.t
  ; cache : D.t option
  }

let init ~root ~anchor_path =
  let anchor_path = root / anchor_path in
  let anchor = Anchor.read anchor_path in
  let cache = Anchor.cache_root anchor |> Option.map @@ fun cache_root ->
    D.init ~root:(root / cache_root)
  in
  {root; anchor_path; anchor; cache}

let save_cache {cache; _} =
  Option.fold ~none:() ~some:D.save cache

(** @param suffix The suffix should include the dot. *)
let locate_anchor_and_init ~anchor_path ~suffix filepath =
  if not @@ Sys.file_exists filepath then
    invalid_arg @@ "init_from_filepath: " ^ filepath ^ " does not exist";
  if not @@ Filename.is_relative anchor_path then
    invalid_arg @@ "init_from_filepath: " ^ anchor_path ^ " should be a relative path";
  match Filename.chop_suffix_opt ~suffix @@ Filename.basename filepath with
  | None -> invalid_arg @@ "init_from_filepath: " ^ filepath ^ " does not have suffix " ^ suffix
  | Some basename ->
    let rec find_root cwd unitpath_acc =
      if is_existing_and_regular anchor_path then
        init ~root:cwd ~anchor_path, unitpath_acc
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

(** @param suffix The suffix should include the dot. *)
let to_filepath = dispatch_path to_local_filepath

(** Generate the JSON [key] from immediately available metadata. *)
let make_local_key path ~source_digest : YamlIO.yaml =
  `O [ "path", `A (List.map (fun s -> `String s) path)
     ; "source_digest", `String source_digest
     ]

let replace_local_cache {cache; _} path ~source_digest value =
  let key = make_local_key path ~source_digest in
  match cache with
  | None -> D.digest_of_item ~key ~value
  | Some cache ->
    D.replace_item cache ~key ~value

let find_local_cache_opt {cache; _} path ~source_digest ~cache_digest =
  Option.bind cache @@ fun cache ->
  let key = make_local_key path ~source_digest in
  D.find_item_opt cache ~key ~digest:cache_digest

let replace_cache = dispatch_path replace_local_cache
let find_cache_opt = dispatch_path find_local_cache_opt
