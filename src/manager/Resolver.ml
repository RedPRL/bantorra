open BantorraBasis

type resolver_argument = Marshal.value
type t =
  { fast_checker: current_root:string -> resolver_argument -> bool
  ; resolver: current_root:string -> resolver_argument -> string option
  ; arg_dumper: current_root:string -> resolver_argument -> string
  }

let make ?fast_checker ?args_dumper resolver =
  let fast_checker = Option.value fast_checker ~default:(fun ~current_root l -> Option.is_some @@ resolver ~current_root l)
  and arg_dumper = Option.value args_dumper ~default:(fun ~current_root:_ l -> Marshal.dump l)
  in
  {fast_checker; resolver; arg_dumper}

let resolve_opt {resolver; _} = resolver
let resolve {resolver; _} ~current_root resolver_argument = Option.get @@ resolver ~current_root resolver_argument
let fast_check {fast_checker; _} = fast_checker
let dump_argument {arg_dumper; _} = arg_dumper
