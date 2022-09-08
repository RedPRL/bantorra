type t =
  [ `System
  | `AnchorNotFound
  | `JSONFormat
  | `UnitNotFound
  | `InvalidLibrary
  | `InvalidRouter
  ]

let default_severity _ = Asai.Severity.Error

let to_string : t -> string =
  function
  | `System -> "sys"
  | `AnchorNotFound -> "anchor"
  | `JSONFormat -> "json"
  | `UnitNotFound -> "unit"
  | `InvalidLibrary -> "lib"
  | `InvalidRouter -> "router"
