(** Error codes. *)

(** Type of error codes. See the Asai documentation. *)
type t =
  [ `System
  | `AnchorNotFound
  | `JSONFormat
  | `UnitNotFound
  | `InvalidLibrary
  | `InvalidRoute
  | `InvalidRouter
  | `Web
  ]

(** Default severity of error codes. See the Asai documentation. *)
let default_severity =
  function
  | `InvalidRouter -> Asai.Diagnostic.Bug
  | _ -> Asai.Diagnostic.Error

(** String representation of error codes. See the Asai documentation. *)
let to_string : t -> string =
  function
  | `System -> "sys"
  | `AnchorNotFound -> "anchor"
  | `JSONFormat -> "json"
  | `UnitNotFound -> "unit"
  | `InvalidLibrary -> "lib"
  | `InvalidRoute -> "route"
  | `InvalidRouter -> "router"
  | `Web -> "web"
