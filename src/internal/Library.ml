type t =
  { root : FilePath.t
  ; anchor : string
  ; loaded_anchor : Anchor.t
  }

let (/) = FilePath.add_unit_seg

let load_from_root ~version ~premount ~find_cache ~anchor root =
  Logger.tracef "@[<2>When loading library at its root:@ version=%s, anchor=%s, root=%a@]"
    version anchor (FilePath.pp ~relative_to:(File.get_cwd ())) root @@ fun () ->
  let root = FilePath.to_dir_path root in
  match find_cache root with
  | Some lib -> lib
  | None ->
    let loaded_anchor = Anchor.read ~version ~premount (root/anchor) in
    {root; anchor; loaded_anchor}

let load_from_dir ~version ~premount ~find_cache ~anchor dir =
  Logger.tracef "@[<2>When loading library from a directory:@ version=%s, anchor=%s, dir=%a)@]"
    version anchor (FilePath.pp ~relative_to:(File.get_cwd ())) dir @@ fun () ->
  let dir = FilePath.to_dir_path dir in
  match File.locate_anchor ~anchor dir with
  | root, prefix ->
    let lib = load_from_root ~version ~premount ~find_cache ~anchor root in
    if Anchor.path_is_local lib.loaded_anchor prefix
    then lib, Some prefix
    else lib, None

let load_from_unit ~version ~premount ~find_cache ~anchor filepath ~suffix =
  Logger.tracef "@[<2>When loading library from a unit:@ version=%s, anchor=%s, filepath=%a, suffix=%s)"
    version anchor (FilePath.pp ~relative_to:(File.get_cwd ())) filepath suffix @@ fun () ->
  if not @@ File.file_exists filepath then
    Logger.fatalf `InvalidLibrary "The unit `%a' does not exist" (FilePath.pp ~relative_to:(File.get_cwd ())) filepath
  else
  if FilePath.has_ext suffix filepath then
    Logger.fatalf `InvalidLibrary "The file path `%a' does not have the suffix `%s'" (FilePath.pp ~relative_to:(File.get_cwd ())) filepath suffix;
  let filepath = FilePath.rem_ext filepath in
  let root, path_opt =
    load_from_dir ~version ~premount ~find_cache ~anchor (FilePath.parent filepath)
  in
  root, Option.map (fun path -> UnitPath.add_seg path (FilePath.basename filepath)) path_opt

let root lib = lib.root

let dispatch_path ~depth local ~global (lib : t) (path : UnitPath.t) =
  Logger.tracef "When dispatching the path `%a'" UnitPath.pp path @@ fun () ->
  match Anchor.dispatch_path lib.loaded_anchor path with
  | None -> local lib path
  | Some (route, path) ->
    global ~depth:(depth+1) ?starting_dir:(Some lib.root) route path

let resolve_local lib path ~suffix =
  Logger.tracef "When resolving local path `%a'" UnitPath.pp path @@ fun () ->
  if UnitPath.is_root path then Logger.fatalf `InvalidLibrary "Unit path is empty";
  match File.locate_hijacking_anchor ~anchor:lib.anchor ~root:lib.root path with
  | Some anchor ->
    Logger.fatalf `InvalidLibrary
      "The unit `%a' does not belong to the library `%a' because `%a' exists"
      UnitPath.pp path
      (FilePath.pp ~relative_to:(File.get_cwd ())) lib.root
      (FilePath.pp ~relative_to:(File.get_cwd ())) anchor
  | None ->
    lib, path, FilePath.add_ext suffix (FilePath.append_unit lib.root path)

(** @param suffix The suffix should include the dot. *)
let resolve ~depth = dispatch_path ~depth resolve_local
