open BantorraBasis

type info = Marshal.value
type t =
  { fast_checker: cur_root:string -> info -> bool
  ; resolver: cur_root:string -> info -> string option
  ; args_dumper: cur_root:string -> info -> string
  }

let make ?fast_checker ?args_dumper resolver =
  let fast_checker = Option.value fast_checker ~default:(fun ~cur_root l -> Option.is_some @@ resolver ~cur_root l)
  and args_dumper = Option.value args_dumper ~default:(fun ~cur_root:_ l -> Marshal.dump l)
  in
  {fast_checker; resolver; args_dumper}

let resolve_opt {resolver; _} = resolver
let resolve {resolver; _} ~cur_root info = Option.get @@ resolver ~cur_root info
let fast_check {fast_checker; _} = fast_checker
let dump_args {args_dumper; _} = args_dumper
