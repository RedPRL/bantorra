module E = Errors
open BantorraBasis
open ResultMonad.Syntax

type unitpath = Anchor.unitpath

type t =
  { root : File.filepath
  ; anchor : string
  ; loaded_anchor : Anchor.t
  }

let load_from_root ~find_cache ~anchor root =
  let src = "Library.load_from_root" in
  match find_cache root with
  | Some lib -> ret lib
  | None ->
    match Anchor.read File.(root/anchor) with
    | Ok loaded_anchor -> ret {root; anchor; loaded_anchor}
    | Error (`SystemError msg | `FormatError msg) ->
      E.append_error_invalid_library_msgf ~earlier:msg ~src
        "Could not parse the anchor %s" File.(root/anchor)

let load_from_dir ~find_cache ~anchor dir =
  let src = "Library.load_from_dir" in
  match File.locate_anchor ~anchor dir with
  | Error (`AnchorNotFound msg) ->
    E.append_error_invalid_library_msgf ~earlier:msg ~src
      "Could not find any anchor in the ancestors of %s" dir
  | Ok (root, prefix) ->
    let+ lib = load_from_root ~find_cache ~anchor root in
    if Anchor.path_is_local lib.loaded_anchor prefix
    then lib, Some prefix
    else lib, None

let load_from_unit ~find_cache ~anchor filepath ~suffix =
  let src = "Library.load_from_unit" in
  if not @@ File.file_exists filepath then
    E.error_invalid_library_msgf ~src
      "The unit %s does not exist" filepath
  else
    match Filename.chop_suffix_opt ~suffix @@ Filename.basename filepath with
    | None ->
      E.error_invalid_library_msgf ~src
        "The file path %s does not have the suffix `%s'" filepath suffix
    | Some basename ->
      let+ root, unitpath_opt =
        load_from_dir ~find_cache ~anchor @@ Filename.dirname filepath
      in
      root, Option.map (fun unitpath -> unitpath @ [basename]) unitpath_opt

let root lib = lib.root

let iter_routes f lib = Anchor.iter_routes f lib.loaded_anchor

let dispatch_path local ~global (lib : t) (path : unitpath) =
  match Anchor.dispatch_path lib.loaded_anchor path with
  | None -> local lib path
  | Some (router, router_argument, path) ->
    global ~router ~router_argument ~starting_dir:lib.root path

let resolve_local lib path ~suffix =
  let src = "Library.resolve_local" in
  match path with
  | [] -> E.error_unit_not_found_msgf ~src "No unit at the root (%s)" lib.root
  | path ->
    if File.hijacking_anchors_exist ~anchor:lib.anchor ~root:lib.root path then
      E.error_unit_not_found_msgf ~src
        "The unit path %a does not belong to the library (%s) but a library at its subdirectory. \
         Check all the files named `%s' within the directory %s."
        Util.pp_unitpath path lib.root lib.anchor lib.root
    else
      ret (lib, path, File.join (lib.root :: path) ^ suffix)

(** @param suffix The suffix should include the dot. *)
let resolve ~global = dispatch_path resolve_local ~global
