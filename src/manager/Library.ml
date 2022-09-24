open BantorraBasis
module E = Error

type t =
  { root : File.path
  ; anchor : string
  ; loaded_anchor : Anchor.t
  }

let (/) = FilePath.add_unit_seg

let load_from_root ~version ~find_cache ~anchor root =
  E.tracef "Library.load_from_root(%s,-,%s,%a)" version anchor FilePath.pp root @@ fun () ->
  let root = FilePath.to_dir_path root in
  match find_cache root with
  | Some lib -> lib
  | None ->
    let loaded_anchor = Anchor.read ~version (root/anchor) in
    {root; anchor; loaded_anchor}

let load_from_dir ~version ~find_cache ~anchor dir =
  E.tracef "Library.load_from_dir(%s,-,%s,%a)" version anchor FilePath.pp dir @@ fun () ->
  let dir = FilePath.to_dir_path dir in
  match File.locate_anchor ~anchor dir with
  | root, prefix ->
    let lib = load_from_root ~version ~find_cache ~anchor root in
    if Anchor.path_is_local lib.loaded_anchor prefix
    then lib, Some prefix
    else lib, None

let load_from_unit ~version ~find_cache ~anchor filepath ~suffix =
  E.tracef "Library.load_from_dir(%s,-,%s,%a,%s)" version anchor FilePath.pp filepath suffix @@ fun () ->
  if not @@ File.file_exists filepath then
    E.fatalf `InvalidLibrary "The unit %a does not exist" FilePath.pp filepath
  else
  if FilePath.has_ext suffix filepath then
    E.fatalf `InvalidLibrary "The file path %a does not have the suffix `%s'" FilePath.pp filepath suffix;
  let filepath = FilePath.rem_ext filepath in
  let root, path_opt =
    load_from_dir ~version ~find_cache ~anchor (FilePath.parent filepath)
  in
  root, Option.map (fun path -> UnitPath.add_seg path (FilePath.basename filepath)) path_opt

let root lib = lib.root

let dispatch_path ~depth local ~global (lib : t) (path : UnitPath.t) =
  E.tracef "Library.dispatch_path" @@ fun () ->
  match Anchor.dispatch_path lib.loaded_anchor path with
  | None -> local lib path
  | Some (route, path) ->
    global ~depth:(depth+1) ~lib_root:lib.root route path

let resolve_local lib path ~suffix =
  E.tracef "Library.resolve_local" @@ fun () ->
  if UnitPath.is_root path then E.fatalf `InvalidLibrary "Unit path is empty";
  match File.locate_hijacking_anchor ~anchor:lib.anchor ~root:lib.root path with
  | Some anchor ->
    E.fatalf `InvalidLibrary
      "The unit `%a' does not belong to the library `%a' because `%a' exists"
      UnitPath.pp path FilePath.pp lib.root FilePath.pp anchor
  | None ->
    lib, path, FilePath.add_ext suffix (FilePath.append_unit lib.root path)

(** @param suffix The suffix should include the dot. *)
let resolve ~depth = dispatch_path ~depth resolve_local
