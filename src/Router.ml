module E = Error

type param = Json_repr.ezjsonm
type t = param -> FilePath.t
type pipe = param -> param

module Eff = Algaeff.Reader.Make(struct type env = FilePath.t option end)
let get_starting_dir = Eff.read
let run ?starting_dir = Eff.run ~env:starting_dir

type table = (Marshal.value, Marshal.value) Hashtbl.t

let read_config = ConfigFile.read

let write_config = ConfigFile.write

let dispatch lookup param =
  let name, param = Marshal.destruct Json_encoding.(tup2 string any_ezjson_value) param in
  match lookup name with
  | Some route -> route param
  | None -> E.fatalf `InvalidRoute "Router %s does not exist" name

let fix ?(hop_limit=10) (f : t -> t) route =
  let rec go i route =
    if i <= 0 then
      E.fatalf `InvalidLibrary "Exceeded hop limit (%d)" hop_limit
    else
      f (go (i-1)) route
  in
  f (go hop_limit) route

let git = Git.route

let local ?relative_to ~expanding_tilde param =
  let path = Marshal.destruct Json_encoding.string param in
  let expanding_tilde = if expanding_tilde then Some (File.get_home ()) else None in
  FilePath.of_string ?relative_to ?expanding_tilde path

let rewrite ?(recursively=false) ?(err_on_missing=false) lookup param =
  let param = Marshal.normalize param in
  let rec go param =
    match lookup param with
    | None -> if err_on_missing then E.fatalf `InvalidRoute "Entry %s does not exist" (Marshal.to_string param) else param
    | Some param -> if recursively then go param else param
  in go param
