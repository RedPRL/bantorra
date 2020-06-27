open StdLabels
open BantorraBasis
open BantorraBasis.File
open Bantorra

type url = string

let default_crate_subdir = "_crate"
let git_subdir = "_git"

type t =
  { root : string
  ; known_ids : (string, string) Hashtbl.t
  }

type info =
  { url : string
  ; ref : string
  ; path : string
  }

let loaded_crates : (string, t) Hashtbl.t = Hashtbl.create 5

module G =
struct
  let resolve_ref ~url ~ref =
    Exec.with_system_in ~prog:"git" ~args:["ls-remote"; "--heads"; "--tags"; url; ref] @@ fun ic ->
    match String.split_on_char ~sep:'\t' @@ String.trim @@ input_line ic with
    | [ref; _] -> ref
    | _ -> failwith "git ls-remote failed"

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

let load_git_repo ~crate:{root; known_ids} {url; ref; path} =
  let url_digest = Marshal.digest @@ `String url in
  let id = G.resolve_ref ~url ~ref in
  if Option.fold ~none:false ~some:((<>) id) @@ Hashtbl.find_opt known_ids url_digest then
    failwith @@ "Inconsistent commit IDs for the repo "^url^" (or very unlikely URL hash collision)";
  Hashtbl.replace known_ids url_digest id;
  let git_root = root / git_subdir / url_digest in
  G.reset_repo ~git_root ~url ~ref;
  normalize_dir @@ git_root / path

let init_crate ~root =
  match Hashtbl.find_opt loaded_crates root with
  | Some c -> c
  | None ->
    let crate = {root; known_ids = Hashtbl.create 10} in
    Hashtbl.replace loaded_crates root crate;
    crate

let resolver ~root =
  let root = normalize_dir root in
  let crate = init_crate ~root in
  let fast_checker ~cur_root:_ _ = true
  and resolver ~cur_root:_ arg =
    try Option.some @@ load_git_repo ~crate @@ M.to_info arg with _ -> None
  in
  Resolver.make ~fast_checker resolver
