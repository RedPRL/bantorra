module E = Errors
open BantorraBasis
open ResultMonad.Syntax
open Bantorra

let git_subdir = "_git"

type t =
  { root : string
  ; id_in_use : (string, string) Hashtbl.t
  ; url_in_use : (string, string) Hashtbl.t
  }

type info =
  { url : string
  ; ref : string
  ; path : File.filepath
  }

let loaded_crates : (string, t) Hashtbl.t = Hashtbl.create 5

module G =
struct
  open Bos

  let git ~root = Cmd.(v "git" % "-C" % root)

  let run_null cmd = Bos.OS.Cmd.(in_null |> run_io cmd |> to_null)

  let git_check_ref_format ~root ~ref =
    run_null Cmd.(git ~root % "check-ref-format" %  "--allow-onelevel" % ref)

  let git_init ~root =
    run_null Cmd.(git ~root % "init" %  "--quiet")

  let git_remote_reset_origin ~root ~url =
    ResultMonad.ignore_error @@ run_null Cmd.(git ~root % "remote" % "remove" % "origin");
    run_null Cmd.(git ~root % "remote" % "add" % "origin" % url)

  let git_fetch_origin ~root ~ref =
    run_null Cmd.(git ~root % "fetch" % "--quiet" % "--no-tags" % "--recurse-submodules=on-demand" % "--depth=1" % "origin" % ref)

  let git_reset ~root =
    run_null Cmd.(git ~root % "reset" % "--quiet" % "--hard" % "--recurse-submodules" % "FETCH_HEAD" % "--")

  let git_rev_parse ~root ~ref =
    Bos.OS.Cmd.(in_null |> run_io Cmd.(git ~root % "rev-parse" % "--verify" % "--end-of-options" % ref) |> to_string)

  let reset_repo ~url ~ref ~root ~id_in_use =
    let src = "Git.reset_repo" in
    match
      let* () = File.ensure_dir root in
      File.normalize_dir root
    with
    | Error (`SystemError msg) ->
      E.append_error_invalid_library_msgf ~earlier:msg ~src "Not a directory: %s" root
    | Ok root ->
      let* () = git_init ~root in
      let* () = git_check_ref_format ~root ~ref in
      let* () = git_remote_reset_origin ~root ~url in
      let* () = git_fetch_origin ~root ~ref in
      match id_in_use with
      | None ->
        let* () = git_reset ~root in
        git_rev_parse ~root ~ref:"HEAD"
      | Some id_in_use ->
        let* () = git_reset ~root in
        let* id = git_rev_parse ~root ~ref:"HEAD" in
        if id_in_use <> id then
          E.error_invalid_library_msgf ~src "Inconsistent comments in use: %s and %s for %s" id id_in_use url
        else
          ret id
end

module M =
struct
  let to_info v =
    Marshal.parse_object ~required:["url"] ~optional:["ref"; "path"] v >>=
    function
    | ["url", url], ["ref", ref; "path", path] ->
      let* url = Marshal.to_string url in
      let* ref = Option.value ~default:"HEAD" <$> Marshal.to_ostring ref in
      let* path =
        Option.fold ~none:Filename.current_dir_name ~some:File.input_relative_dir <$>
        Marshal.to_ostring path
      in
      ret {url; ref; path}
    | _ -> assert false
end

(* more checking about [ref] *)
let load_git_repo ~crate:{root; id_in_use; url_in_use} {url; ref; path} =
  let src = "Git.load_git_repo" in
  let url_digest = Digest.to_hex @@ Digest.string url in
  let git_root = File.(root / git_subdir / url_digest) in
  let* () =
    match Hashtbl.find_opt url_in_use url_digest with
    | Some url_in_use when url_in_use <> url ->
      E.error_invalid_library_msgf ~src "Unexpected hash collision for urls %s and %s" url url_in_use
    | _ -> ret ()
  in
  let* commit_id =
    G.reset_repo ~root:git_root ~url ~ref
      ~id_in_use:(Hashtbl.find_opt id_in_use url_digest)
  in
  Hashtbl.replace id_in_use url_digest commit_id;
  Hashtbl.replace url_in_use url_digest url;
  match File.normalize_dir File.(git_root/path) with
  | Error (`SystemError msg) ->
    E.append_error_invalid_library_msg ~earlier:msg ~src "Could not reset the git repository"
  | Ok root -> ret root

let init_crate ~crate_root =
  let src = "Git.init_crate" in
  match File.input_absolute_dir crate_root with
  | Error (`SystemError msg) ->
    E.append_error_invalid_router_msgf ~earlier:msg ~src "Could not create the crate for git repositories at %s" crate_root
  | Ok crate_root ->
    match Hashtbl.find_opt loaded_crates crate_root with
    | Some c -> ret c
    | None ->
      let crate = {root = crate_root; id_in_use = Hashtbl.create 5; url_in_use = Hashtbl.create 5} in
      Hashtbl.replace loaded_crates crate_root crate;
      ret crate

let router ?(eager_resolution=false) ~crate_root =
  let src = "Git.router" in
  let* crate =
    match File.input_absolute_dir crate_root with
    | Error (`SystemError msg) ->
      E.append_error_invalid_router_msgf ~earlier:msg ~src
        "Invalid path %s" crate_root
    | Ok crate_root -> init_crate ~crate_root
  in
  let fast_checker =
    if eager_resolution then None
    else Option.some @@ fun ~starting_dir:_ ~arg ->
      try Result.is_ok @@ M.to_info arg with _ -> false
  in
  ret @@ Router.make ?fast_checker @@ fun ~starting_dir:_ ~arg ->
  let src = "Git.route" in
  match M.to_info arg >>= load_git_repo ~crate with
  | Error (`FormatError msg) ->
    E.append_error_invalid_library_msgf ~earlier:msg ~src
      "Could not parse the argument: %a" Marshal.dump arg
  | Error (`Msg msg | `InvalidLibrary msg) ->
    E.append_error_invalid_library_msgf ~earlier:msg ~src
      "Could not load the git repository at %a" Marshal.dump arg
  | Ok root -> ret root
