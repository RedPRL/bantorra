open BantorraBasis

type res_args = Marshal.value
type t =
  { fast_checker: cur_root:string -> res_args -> bool
  ; resolver: cur_root:string -> res_args -> string option
  ; args_dumper: cur_root:string -> res_args -> string
  }

let make ?fast_checker ?args_dumper resolver =
  let fast_checker = Option.value fast_checker ~default:(fun ~cur_root l -> Option.is_some @@ resolver ~cur_root l)
  and args_dumper = Option.value args_dumper ~default:(fun ~cur_root:_ l -> Marshal.dump l)
  in
  {fast_checker; resolver; args_dumper}

let resolve_opt {resolver; _} = resolver
let resolve {resolver; _} ~cur_root res_args = Option.get @@ resolver ~cur_root res_args
let fast_check {fast_checker; _} = fast_checker
let dump_args {args_dumper; _} = args_dumper
