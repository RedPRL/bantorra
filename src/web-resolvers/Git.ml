open StdLabels
open BantorraBasis
open BantorraBasis.File
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
  ; path : string list
  }

let loaded_crates : (string, t) Hashtbl.t = Hashtbl.create 5

module G =
struct
  let reset_repo ~url ~ref ~git_root ~id_in_use =
    match String.index_opt ref ':' with
    | Some i when i <> String.length ref - 1 (* dst is not empty *) ->
      invalid_arg @@ "reset_repo: refspec "^ref^" has non-empty <dst>. Please remove the part after the colon."
    | _ ->
      try
        File.protect_cwd @@ fun _ ->
        File.ensure_dir git_root;
        Sys.chdir git_root;
        Exec.system ~prog:"git" ~args:["init"; "--quiet"];
        Exec.system ~prog:"git" ~args:["fetch"; "--quiet"; "--no-tags"; "--recurse-submodules=on-demand"; "--depth=1"; "--"; url; ref];
        match id_in_use with
        | None ->
          Exec.system ~prog:"git" ~args:["reset"; "--quiet"; "--hard"; "--"; "FETCH_HEAD"];
          Exec.with_system_in ~prog:"git" ~args:["rev-parse"; "HEAD"] @@ fun ic_id ->
          String.trim @@ input_line ic_id
        | Some id_in_use ->
          Exec.with_system_in ~prog:"git" ~args:["rev-parse"; "FETCH_HEAD"] @@ fun ic_id ->
          if id_in_use <> String.trim @@ input_line ic_id then
            failwith @@ "Inconsistent commit IDs for the repo at: "^url
          else
            id_in_use
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
          ; path = []
          }
        | ["ref", ref; "url", url] ->
          { url = Marshal.to_string url
          ; ref = Marshal.to_string ref
          ; path = []
          }
        | ["path", path; "url", url] ->
          { url = Marshal.to_string url
          ; ref = "HEAD"
          ; path = Marshal.to_list Marshal.to_string path
          }
        | ["path", path; "ref", ref; "url", url] ->
          { url = Marshal.to_string url
          ; ref = Marshal.to_string ref
          ; path = Marshal.to_list Marshal.to_string path
          }
        | _ -> raise Marshal.IllFormed
      end
    | _ -> raise Marshal.IllFormed
end

(* more checking about [ref] *)
let load_git_repo ~crate:{root; id_in_use; url_in_use} {url; ref; path} =
  if url = "origin" then invalid_arg "load_git_repo: url = \"origin\"";
  let url_digest = Digest.to_hex @@ Digest.string url in
  let git_root = root / git_subdir / url_digest in
  begin
    match Hashtbl.find_opt url_in_use url_digest with
    | Some url_in_use when url_in_use <> url ->
      failwith @@ "Unfortunate MD5 hash collision happened: "^url^" and "^url_in_use
    | _ -> ()
  end;
  Hashtbl.replace id_in_use url_digest @@
  G.reset_repo ~git_root ~url ~ref
    ~id_in_use:(Hashtbl.find_opt id_in_use url_digest);
  Hashtbl.replace url_in_use url_digest url;
  normalize_dir @@ join @@ git_root :: path

let init_crate ~crate_root =
  let crate_root = normalize_dir crate_root in
  match Hashtbl.find_opt loaded_crates crate_root with
  | Some c -> c
  | None ->
    let crate = {root = crate_root; id_in_use = Hashtbl.create 5; url_in_use = Hashtbl.create 5} in
    Hashtbl.replace loaded_crates crate_root crate;
    crate

let resolver ~strict_checking ~crate_root =
  let crate = init_crate ~crate_root in
  let fast_checker ~cur_root:_ arg =
    if strict_checking then
      try ignore @@ load_git_repo ~crate @@ M.to_info arg; true with _ -> false
    else
      try ignore @@ M.to_info arg; true with _ -> false
  and resolver ~cur_root:_ arg =
    try Option.some @@ load_git_repo ~crate @@ M.to_info arg with _ -> None
  in
  Resolver.make ~fast_checker resolver
