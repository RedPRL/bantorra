module Code =
struct
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
  let default_severity : t -> Asai.Diagnostic.severity =
    function
    | `InvalidRouter -> Bug
    | _ -> Error

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
end

include Asai.Logger.Make(Code)
