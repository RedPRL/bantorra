open BantorraBasis

type info = Marshal.value
type t =
  { fast_checker: cur_root:string -> info -> bool
  ; resolver: cur_root:string -> info -> string option
  ; info_dumper: cur_root:string -> info -> string
  }

let make ?fast_checker ?info_dumper resolver =
  let fast_checker = Option.value fast_checker ~default:(fun ~cur_root l -> Option.is_some @@ resolver ~cur_root l)
  and info_dumper = Option.value info_dumper ~default:(fun ~cur_root:_ l -> Marshal.dump l)
  in
  {fast_checker; resolver; info_dumper}

let resolve_opt {resolver; _} = resolver
let resolve {resolver; _} ~cur_root info = Option.get @@ resolver ~cur_root info
let fast_check {fast_checker; _} = fast_checker
let dump_info {info_dumper; _} = info_dumper
