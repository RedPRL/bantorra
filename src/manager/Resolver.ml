open BantorraBasis

type info = Marshal.value
type t =
  { checker: info -> bool
  ; resolver: info -> string option
  ; info_dumper: info -> string
  }

let make ?checker ?info_dumper resolver =
  let checker = Option.value checker ~default:(fun l -> Option.is_some @@ resolver l)
  and info_dumper = Option.value info_dumper ~default:(fun l -> Marshal.dump l)
  in
  {checker; resolver; info_dumper}

let resolve_opt {resolver; _} = resolver
let resolve {resolver; _} info = Option.get @@ resolver info
let check {checker; _} = checker
let dump_info {info_dumper; _} = info_dumper
