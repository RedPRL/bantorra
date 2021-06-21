open BantorraBasis
open BantorraBasis.File
open ResultMonad.Syntax

type unitpath = Anchor.unitpath

type t =
  { root : filepath
  ; anchor : string
  ; loaded_anchor : Anchor.t
  }

let unit_resolve_error fmt =
  Printf.ksprintf (fun s -> error @@ `UnitNotFound (Printf.sprintf "Library.route: %s" s)) fmt

let load_from_root ~find_cache ~anchor root =
  match find_cache root with
  | Some lib -> ret lib
  | None ->
    match Anchor.read @@ root / anchor with
    | Ok loaded_anchor -> ret {root; anchor; loaded_anchor}
    | Error (`SystemError msg | `FormatError msg) ->
      Router.library_load_error "%s" msg

let load_from_dir ~find_cache ~anchor dir =
  match File.locate_anchor ~anchor dir with
  | Error (`AnchorNotFound msg) -> Router.library_load_error "no anchor found: %s" msg
  | Ok (root, prefix) ->
    let+ lib = load_from_root ~find_cache ~anchor root in
    if Anchor.is_local lib.loaded_anchor prefix
    then lib, Some prefix
    else lib, None

let load_from_unit ~find_cache ~anchor ~suffix filepath =
  if not @@ Sys.file_exists filepath then
    Router.library_load_error "%s does not exist" filepath
  else
    match Filename.chop_suffix_opt ~suffix @@ Filename.basename filepath with
    | None -> Router.library_load_error "%s does not have suffix %s" filepath suffix
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
  | Some (lib_ref, path) -> global ~starting_dir:lib.root lib_ref path

let resolve_local lib path ~suffix =
  match path with
  | [] -> unit_resolve_error "%s: no unit at the root" lib.root
  | path ->
    if File.check_intercepting_anchors ~anchor:lib.anchor lib.root path then
      unit_resolve_error "%s: %s belongs to a different library" lib.root (Util.string_of_unitpath path)
    else
      ret (lib, path, File.join (lib.root :: path) ^ suffix)

(** @param suffix The suffix should include the dot. *)
let resolve ~global = dispatch_path resolve_local ~global
