open Basis
open Basis.File
module D = Cache.Database

type path = string list

let default_cache_subdir = "_cache"

type t =
  { root: string
  ; anchor: string
  ; cache: D.t
  }

let init ~root ?(cache_subdir=default_cache_subdir) ~anchor =
  { root
  ; anchor
  ; cache = D.init ~root:(root/cache_subdir)
  }

(** @param suffix The suffix should include the dot. *)
let init_from_filepath ?cache_subdir ~anchor ~suffix filepath =
  if not @@ Sys.file_exists filepath then
    invalid_arg ("init_from_filepath: " ^ filepath ^ " does not exist");
  let dirname, basename = split_path filepath in
  match Filename.chop_suffix_opt ~suffix basename with
  | None -> invalid_arg "init_from_filepath: wrong suffix"
  | Some basename ->
    let rec find_root normalized_cwd acc =
      if is_existing_and_regular anchor then
        init ~root:normalized_cwd ?cache_subdir ~anchor, acc
      else
        let parent, basename = split_path normalized_cwd in
        if parent = normalized_cwd then
          raise Not_found
        else begin
          Sys.chdir parent;
          find_root parent @@ basename :: acc
        end
    in
    protect_cwd @@ fun _ ->
    Sys.chdir dirname;
    find_root (Sys.getcwd ()) [basename]

(** @param suffix The suffix should include the dot. *)
let to_filepath {root; _} ~suffix =
  function
  | [] -> invalid_arg "to_rel_filepath: empty unit path"
  | l -> root / String.concat Filename.dir_sep l ^ suffix

(** Generate the JSON [key] from immediately available metadata. *)
let make_key path ~source_digest : JSON.json_value =
  `O [ "path", `A (List.map (fun s -> `String s) path)
     ; "source_digest", `String (Digest.to_hex source_digest)
     ]

let replace_cache {cache; _} path ~source_digest value =
  let key = make_key path ~source_digest in
  D.replace_item cache ~key ~value

let find_cache_opt {cache; _} path ~source_digest ~cache_digest =
  let key = make_key path ~source_digest in
  D.find_item_opt cache ~key ~digest:cache_digest
