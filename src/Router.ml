type param = Json_repr.ezjsonm
type t = param -> FilePath.t
type pipe = param -> param

type env = {version : string; starting_dir : FilePath.t option}
module Eff = Algaeff.Reader.Make(struct type nonrec env = env end)
let get_version () = (Eff.read ()).version
let get_starting_dir () = (Eff.read ()).starting_dir
let run ~version ?starting_dir = Eff.run ~env:{version; starting_dir}

let dispatch lookup param =
  let name, param = Marshal.destruct Json_encoding.(tup2 string any_ezjson_value) param in
  match lookup name with
  | Some route -> route param
  | None -> Logger.fatalf `InvalidRoute "Router %s does not exist" name

let fix ?(hop_limit=255) (f : t -> t) route =
  let rec go i route =
    if i <= 0 then
      Logger.fatalf `InvalidLibrary "Exceeded hop limit (%d)" hop_limit
    else
      f (go (i-1)) route
  in
  f (go hop_limit) route

let git = Git.route

let file ?relative_to ~expanding_tilde param =
  let path = Marshal.destruct Json_encoding.string param in
  let expanding_tilde = if expanding_tilde then Some (File.get_home ()) else None in
  FilePath.of_string ?relative_to ?expanding_tilde path

let rewrite_try_once lookup param =
  let param = Marshal.normalize param in
  Option.value ~default:param (lookup param)

let rewrite_err_on_missing lookup param =
  let param = Marshal.normalize param in
  match lookup param with
  | None -> Logger.fatalf `InvalidRoute "Entry `%s' does not exist" (Marshal.to_string param)
  | Some param -> param

let rewrite_recursively max_tries lookup param =
  let rec go i =
    if i = max_tries then
      Logger.fatalf `InvalidRoute "Could not resolve %s within %i rewrites" (Marshal.to_string param) max_tries
    else
      let param = Marshal.normalize param in
      match lookup param with
      | None -> go (i+1)
      | Some param -> param
  in go 0

let rewrite ?(mode=`TryOnce) lookup param =
  match mode with
  | `TryOnce -> rewrite_try_once lookup param
  | `ErrOnMissing -> rewrite_err_on_missing lookup param
  | `Recursively i -> rewrite_recursively i lookup param

(** Configuration files *)

type table = Table.t
let lookup_table = Table.lookup
let parse_table s = Table.parse ~version:(get_version ()) s
let read_table p = Table.read ~version:(get_version ()) p
let get_web_table u = Table.get_web ~version:(get_version ()) u
let write_table p tbl = Table.write ~version:(get_version ()) p tbl
