(** Unsafe because it does not restore Sys.getcwd. *)
let unsafe_locate_root_from_cwd anchor cwd unitpath =
  let rec go cwd unitpath =
    if Sys.file_exists anchor && not @@ Sys.is_directory anchor then
      cwd, unitpath
    else
      let parent = Sys.chdir Filename.parent_dir_name; Sys.getcwd () in
      Sys.chdir parent;
      if Sys.getcwd () = cwd then
        raise Not_found
      else
        let basename = Filename.basename cwd in
        go parent @@ basename :: unitpath
  in
  go cwd unitpath

(** @args suffix The suffix (including the dot). *)
let locate_root_from_filepath anchor ~suffix filepath =
  let basename = Filename.basename filepath
  and dirname = Filename.dirname filepath in
  match Filename.chop_suffix_opt ~suffix basename with
  | None -> invalid_arg "locate_root_from_path: wrong suffix"
  | Some basename ->
    Util.protect_cwd @@ fun _ ->
    let new_cwd = Sys.chdir dirname; Sys.getcwd () in
    unsafe_locate_root_from_cwd anchor new_cwd [basename]

(** @args suffix The suffix (including the dot). *)
let rec unitpath_to_relative_filepath ~suffix =
  function
  | [] -> invalid_arg "unitpath_to_relative_filepath: empty name"
  | [basename] -> basename ^ suffix
  | dir :: unitpath ->
    Filename.concat dir @@ unitpath_to_relative_filepath ~suffix unitpath

let unitpath_to_absolute_filepath root ~suffix unitpath =
  Filename.concat root @@ unitpath_to_relative_filepath ~suffix unitpath
