open StdLabels
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
  let git_init () =
    match Exec.system ~prog:"git" ~args:["init"; "--quiet"] with
    | Error (`Exit _ | `Signaled _ | `Stopped _) ->
      Router.library_load_error "Git.reset_repo: `git init' failed"
    | Error (`SystemError msg) ->
      Router.library_load_error "Git.reset_repo: `git init' failed: %s" msg
    | Ok () -> ret ()

  let git_fetch ~url ~ref =
    match
      Exec.system ~prog:"git"
        ~args:["fetch"; "--quiet"; "--no-tags"; "--recurse-submodules=on-demand"; "--depth=1"; "--"; url; ref]
    with
    | Error (`Exit _ | `Signaled _ | `Stopped _) ->
      Router.library_load_error "Git.reset_repo: `git fetch' failed"
    | Error (`SystemError msg) ->
      Router.library_load_error "Git.reset_repo: `git fetch' failed: %s" msg
    | Ok () -> ret ()

  let git_reset () =
    match
      Exec.system ~prog:"git"
        ~args:["reset"; "--quiet"; "--hard"; "--recurse-submodules"; "FETCH_HEAD"; "--"]
    with
    | Error (`Exit _ | `Signaled _ | `Stopped _) ->
      Router.library_load_error "Git.reset_repo: `git reset' failed"
    | Error (`SystemError msg) ->
      Router.library_load_error "Git.reset_repo: `git fetch' failed: %s" msg
    | Ok () -> ret ()

  let git_rev_parse ~ref =
    match
      Exec.with_system_in ~prog:"git" ~args:["rev-parse"; ref] @@ fun ic_id ->
      String.trim @@ try input_line ic_id with End_of_file -> ""
    with
    | Error (`Exit _ | `Signaled _ | `Stopped _) ->
      Router.library_load_error "Git.reset_repo: `git rev-parse' failed"
    | Error (`SystemError msg) ->
      Router.library_load_error "Git.reset_repo: `git rev-parse' failed: %s" msg
    | Ok id -> ret id

  let reset_repo ~url ~ref ~git_root ~id_in_use =
    match String.index_opt ref ':' with
    | Some i when i <> String.length ref - 1 (* dst is not empty *) ->
      Router.library_load_error "Git.reset_repo: unsupported <dst> after the colon in %s" ref
    | _ ->
      File.protect_cwd @@ fun _ ->
      match
        let* () = File.ensure_dir git_root in
        File.safe_chdir git_root
      with
      | Error (`SystemError msg) ->
        Router.library_load_error "Git.reset_repo: %s" msg
      | Ok () ->
        let* () = git_init () in
        let* () = git_fetch ~url ~ref in
        match id_in_use with
        | None ->
          let* () = git_reset () in
          git_rev_parse ~ref:"HEAD"
        | Some id_in_use ->
          let* () = git_reset () in
          let* id = git_rev_parse ~ref:"HEAD" in
          if id_in_use <> id then
            Router.library_load_error "Git.reset_repo: inconsistent commits in use: %s and %s at %s." id id_in_use url
          else
            ret id
end

module M =
struct
  let to_info : Marshal.value -> _ =
    function
    | `O ms ->
      Marshal.parse_object_fields ~required:["url"] ~optional:["ref"; "path"] ms >>=
      begin function
        | ["url", url], ["ref", ref; "path", path] ->
          let* url = Marshal.to_string url in
          let* ref = Option.value ~default:"HEAD" <$> Marshal.to_ostring ref in
          let* path = Option.value ~default:Filename.current_dir_name <$> Marshal.to_ostring path in
          ret {url; ref; path}
        | _ -> assert false
      end
    | v ->
      Marshal.invalid_arg ~f:"Git.route" v "invalid argument"
end

(* more checking about [ref] *)
let load_git_repo ~crate:{root; id_in_use; url_in_use} {url; ref; path} =
  if url = "origin" then
    Router.library_load_error "Git.route: `url' is `origin'"
  else
    let url_digest = Digest.to_hex @@ Digest.string url in
    let git_root = File.(root / git_subdir / url_digest) in
    let* () =
      match Hashtbl.find_opt url_in_use url_digest with
      | Some url_in_use when url_in_use <> url ->
        Router.library_load_error "Git.route: unexpected hash collision for urls %s and %s" url url_in_use
      | _ -> ret ()
    in
    let* commit_id =
      G.reset_repo ~git_root ~url ~ref
        ~id_in_use:(Hashtbl.find_opt id_in_use url_digest)
    in
    Hashtbl.replace id_in_use url_digest commit_id;
    Hashtbl.replace url_in_use url_digest url;
    match File.normalize_dir File.(git_root/path) with
    | Error (`SystemError msg) ->
      Router.library_load_error "Git.route: %s." msg
    | Ok root -> ret root

let init_crate ~crate_root =
  match File.normalize_dir crate_root with
  | Error (`SystemError msg) -> Router.invalid_router_error ~maker:"Git.router" "%s" msg
  | Ok crate_root ->
    match Hashtbl.find_opt loaded_crates crate_root with
    | Some c -> ret c
    | None ->
      let crate = {root = crate_root; id_in_use = Hashtbl.create 5; url_in_use = Hashtbl.create 5} in
      Hashtbl.replace loaded_crates crate_root crate;
      ret crate

let router ?(eager_resolution=false) ~crate_root =
  let* crate = init_crate ~crate_root in
  let fast_checker ~starting_dir:_ arg =
    if eager_resolution then
      try
        Result.is_ok @@ (M.to_info arg >>= load_git_repo ~crate)
      with _ -> false
    else
      try Result.is_ok @@ M.to_info arg with _ -> false
  and resolver ~starting_dir:_ arg =
    match M.to_info arg with
    | Error (`FormatError msg) -> Router.library_load_error "Git.route: %s" msg
    | Ok arg -> load_git_repo ~crate arg
  in
  ret @@ Router.make ~fast_checker resolver
