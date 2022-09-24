type t =
  [ `System
  | `AnchorNotFound
  | `JSONFormat
  | `UnitNotFound
  | `InvalidLibrary
  | `InvalidRoute
  | `InvalidRouter
  ]

let default_severity =
  function
  | `InvalidRouter -> Asai.Severity.Bug
  | _ -> Asai.Severity.Error

let to_string : t -> string =
  function
  | `System -> "sys"
  | `AnchorNotFound -> "anchor"
  | `JSONFormat -> "json"
  | `UnitNotFound -> "unit"
  | `InvalidLibrary -> "lib"
  | `InvalidRoute -> "route"
  | `InvalidRouter -> "router"
