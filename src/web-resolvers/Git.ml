open StdLabels
open BantorraBasis
open BantorraBasis.File
open Bantorra

type url = string

let git_subdir = "_git"

type t =
  { root : string
  ; commit_id : (string, string) Hashtbl.t
  }

type info =
  { url : string
  ; ref : string
  ; path : string
  }

let loaded_crates : (string, t) Hashtbl.t = Hashtbl.create 5

module G =
struct
  let head_commit_id ~git_root =
    File.protect_cwd @@ fun _ ->
    Sys.chdir git_root;
    Exec.with_system_in ~prog:"git" ~args:["rev-parse"; "HEAD"] @@ fun ic ->
    String.trim @@ input_line ic

  let reset_repo ~url ~ref ~git_root =
    try
      File.protect_cwd @@ fun _ ->
      File.ensure_dir git_root;
      Sys.chdir git_root;
      Exec.system ~prog:"git" ~args:["init"];
      Exec.system ~prog:"git" ~args:["fetch"; "--depth=1"; url; ref];
      Exec.system ~prog:"git" ~args:["reset"; "--hard"; "FETCH_HEAD"]
    with _ -> failwith "git init/fetch/reset failed"
end

module M =
struct
  let to_info : Marshal.value -> info =
    function
    | `O ms ->
      begin
        (* XXX a better helper function to deal with optional arguments *)
        match List.sort ~cmp:Stdlib.compare ms with
        | ["url", url] ->
          { url = Marshal.to_string url
          ; ref = "HEAD"
          ; path = "."
          }
        | ["ref", ref; "url", url] ->
          { url = Marshal.to_string url
          ; ref = Marshal.to_string ref
          ; path = "."
          }
        | ["path", path; "url", url] ->
          { url = Marshal.to_string url
          ; ref = "HEAD"
          ; path = Marshal.to_string path
          }
        | ["path", path; "ref", ref; "url", url] ->
          { url = Marshal.to_string url
          ; ref = Marshal.to_string ref
          ; path = Marshal.to_string path
          }
        | _ -> raise Marshal.IllFormed
      end
    | _ -> raise Marshal.IllFormed
end

let load_git_repo ~crate:{root; commit_id} {url; ref; path} =
  let url_digest = Marshal.digest @@ `String url in
  let git_root = root / git_subdir / url_digest in
  G.reset_repo ~git_root ~url ~ref;
  let id = G.head_commit_id ~git_root in
  begin
    match Hashtbl.find_opt commit_id url_digest with
    | None -> Hashtbl.replace commit_id url_digest id
    | Some id' ->
      if id <> id' then failwith @@
        "Inconsistent commit IDs for the repo "^url^" (or very unlikely URL hash collision)"
  end;
  normalize_dir @@ git_root / path

let init_crate ~crate_root =
  match Hashtbl.find_opt loaded_crates crate_root with
  | Some c -> c
  | None ->
    let crate = {root = crate_root; commit_id = Hashtbl.create 5} in
    Hashtbl.replace loaded_crates crate_root crate;
    crate

let resolver ~crate_root =
  let crate_root = normalize_dir crate_root in
  let crate = init_crate ~crate_root in
  let fast_checker ~cur_root:_ _ = true
  and resolver ~cur_root:_ arg =
    try Option.some @@ load_git_repo ~crate @@ M.to_info arg with _ -> None
  in
  Resolver.make ~fast_checker resolver
