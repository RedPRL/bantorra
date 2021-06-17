open BantorraBasis
open BantorraBasis.File

type unitpath = Anchor.unitpath

type t =
  { root : string
  ; anchor : Anchor.t
  }

let init ~anchor ~root =
  let anchor = Anchor.read @@ root / anchor in
  {root; anchor}

let locate_anchor_from_dir = File.locate_anchor

let locate_anchor_from_cwd = locate_anchor_from_dir (Sys.getcwd ())

let locate_anchor_from_file ~anchor ~suffix filepath =
  if not @@ Sys.file_exists filepath then
    invalid_arg @@ Printf.sprintf "locate_anchor: %s does not exist" filepath;
  match Filename.chop_suffix_opt ~suffix @@ Filename.basename filepath with
  | None -> invalid_arg @@ Printf.sprintf "locate_anchor: %s does not have suffix %s" filepath suffix
  | Some basename ->
    let root, unitpath = locate_anchor_from_dir ~anchor @@ Filename.dirname filepath in
    root, unitpath @ [basename]

let iter_deps f {anchor; _} = Anchor.iter_deps f anchor

let dispatch_path local ~global lib path =
  match Anchor.dispatch_path lib.anchor path with
  | None -> local lib path
  | Some (lib_name, path) -> global ~current_root:lib.root lib_name path

let to_local_unitpath lib path =
  match path with
  | [] -> invalid_arg "to_unitpath: empty unit path"
  | path -> lib, path

(** @param suffix The suffix should include the dot. *)
let to_local_filepath lib path ~suffix =
  match path with
  | [] -> invalid_arg "to_filepath: empty unit path"
  | path -> lib, File.join (lib.root :: path) ^ suffix

(** @param suffix The suffix should include the dot. *)
let to_unitpath = dispatch_path to_local_unitpath
let to_filepath = dispatch_path to_local_filepath
