open BantorraBasis
module E = Error

type t =
  { root : FilePath.t
  ; lock : Mutex.t
  ; hash_in_use : (string, string) Hashtbl.t
  ; url_in_use : (string, string) Hashtbl.t
  }

let loaded_crates : (FilePath.t, t) Hashtbl.t = Hashtbl.create 5

type param =
  { url : string
  ; ref : string
  ; path : UnitPath.t
  }

module Json =
struct
  module J = Json_encoding

  let url = J.req ~title:"URL" ~description:"Git repository URL to check out" "url" J.string
  let ref = J.dft ~title:"Git ref" ~description:"Git ref or object name (hash) to check out" "ref" J.string "HEAD"
  let path = J.dft ~title:"path" ~description:"path within a Git repository" "path" J.string "./"
  let param = J.obj3 url ref path
end

let parse_param json : param =
  let url, ref, path = Marshal.destruct Json.param json in
  let path = UnitPath.of_string ~accept_dir:true ~allow_extra_dots:true path in
  {url; ref; path}

module G =
struct
  open Bos

  let wrap_bos =
    function
    | Ok r -> r
    | Error (`Msg m) -> E.fatalf `InvalidRoute "%s" m

  let git ~root = Cmd.(v "git" % "-C" % FilePath.to_string root)

  let run_null cmd = wrap_bos @@ Bos.OS.Cmd.(in_null |> run_io cmd |> to_null)

  let git_check_ref_format ~root ~ref =
    run_null Cmd.(git ~root % "check-ref-format" %  "--allow-onelevel" % ref)

  let git_init ~root =
    run_null Cmd.(git ~root % "init" %  "--quiet")

  let git_remote_reset_origin ~root ~url =
    E.try_with ~fatal:(fun _ -> ()) @@ fun () -> run_null Cmd.(git ~root % "remote" % "remove" % "origin");
    run_null Cmd.(git ~root % "remote" % "add" % "origin" % url)

  let git_fetch_origin ~root ~ref =
    run_null Cmd.(git ~root % "fetch" % "--quiet" % "--no-tags" % "--recurse-submodules=on-demand" % "--depth=1" % "origin" % ref)

  let git_reset ~root =
    run_null Cmd.(git ~root % "reset" % "--quiet" % "--hard" % "--recurse-submodules" % "FETCH_HEAD" % "--")

  let git_rev_parse ~root ~ref =
    wrap_bos @@ Bos.OS.Cmd.(in_null |> run_io Cmd.(git ~root % "rev-parse" % "--verify" % "--end-of-options" % ref) |> to_string)

  let reset_repo ~url ~ref ~root ~hash_in_use =
    assert (FilePath.is_dir_path root);
    File.ensure_dir root;
    git_init ~root;
    git_check_ref_format ~root ~ref;
    git_remote_reset_origin ~root ~url;
    git_fetch_origin ~root ~ref;
    match hash_in_use with
    | None ->
      git_reset ~root;
      git_rev_parse ~root ~ref:"HEAD"
    | Some hash_in_use ->
      git_reset ~root;
      let hash = git_rev_parse ~root ~ref:"HEAD" in
      if hash_in_use <> hash then
        E.fatalf `InvalidRoute "Inconsistent Git commits in use: %s and %s for %s" hash hash_in_use url
      else
        hash
end

(* more checking about [ref] *)
let load_git_repo {root; lock; hash_in_use; url_in_use} {url; ref; path} =
  E.tracef "Git.load_git_repo" @@ fun () ->
  Utils.with_mutex lock @@ fun () ->
  let url_digest = Digest.to_hex @@ Digest.string url in
  let git_root = FilePath.append_unit root (UnitPath.of_list ["_git"; url_digest]) in
  begin
    match Hashtbl.find_opt url_in_use url_digest with
    | Some url_in_use when url_in_use <> url ->
      E.fatalf `InvalidRoute "Unexpected hash collision for URLs %s and %s" url url_in_use
    | _ -> ()
  end;
  let hash =
    G.reset_repo ~root:git_root ~url ~ref
      ~hash_in_use:(Hashtbl.find_opt hash_in_use url_digest)
  in
  Hashtbl.replace hash_in_use url_digest hash;
  Hashtbl.replace url_in_use url_digest url;
  FilePath.append_unit git_root path

let global_lock = Mutex.create ()

let load_crate crate_root =
  Utils.with_mutex global_lock @@ fun () ->
  match Hashtbl.find_opt loaded_crates crate_root with
  | Some crate -> crate
  | None -> File.ensure_dir crate_root;
    let crate = {root = crate_root; lock = Mutex.create (); hash_in_use = Hashtbl.create 5; url_in_use = Hashtbl.create 5} in
    Hashtbl.replace loaded_crates crate_root crate;
    crate

let route ~crate =
  let crate = load_crate crate in
  fun param -> load_git_repo crate @@ parse_param param
