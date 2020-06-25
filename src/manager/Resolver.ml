open BantorraBasis

type info = Marshal.value
type t =
  { checker: cur_root:string -> info -> bool
  ; resolver: cur_root:string -> info -> string option
  ; info_dumper: cur_root:string -> info -> string
  }

let make ?checker ?info_dumper resolver =
  let checker = Option.value checker ~default:(fun ~cur_root l -> Option.is_some @@ resolver ~cur_root l)
  and info_dumper = Option.value info_dumper ~default:(fun ~cur_root:_ l -> Marshal.dump l)
  in
  {checker; resolver; info_dumper}

let resolve_opt {resolver; _} = resolver
let resolve {resolver; _} ~cur_root info = Option.get @@ resolver ~cur_root info
let check {checker; _} = checker
let dump_info {info_dumper; _} = info_dumper
