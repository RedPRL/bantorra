open BantorraBasis
open ResultMonad.Syntax

let library_load_error fmt =
  Printf.ksprintf (fun s -> error @@ `InvalidLibrary (Printf.sprintf "Library.load: %s" s)) fmt

type router_argument = Marshal.value
type t =
  { fast_checker: starting_dir:File.filepath -> router_argument -> bool
  ; router: starting_dir:File.filepath -> router_argument -> (File.filepath, [`InvalidLibrary of string]) result
  ; arg_dumper: starting_dir:File.filepath -> router_argument -> string
  }

let make ?fast_checker ?args_dumper router =
  let fast_checker = Option.value fast_checker
      ~default:(fun ~starting_dir l -> Result.is_ok @@ router ~starting_dir l)
  and arg_dumper = Option.value args_dumper
      ~default:(fun ~starting_dir:_ l -> Marshal.dump l)
  in
  {fast_checker; router; arg_dumper}

let route {router; _} ~starting_dir router_argument =
  match router ~starting_dir router_argument with
  | Ok lib -> ret lib
  | Error (`InvalidLibrary s) -> error (`InvalidLibrary s)
let route_opt {router; _} ~starting_dir router_argument =
  Result.to_option @@ router ~starting_dir router_argument
let fast_check {fast_checker; _} = fast_checker
let dump_argument {arg_dumper; _} = arg_dumper
