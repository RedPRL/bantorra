module Message =
struct
  (** Type of error codes. See the asai documentation. *)
  type t =
    | SystemError (** Generic system errors. *)
    | MissingEnvironmentVariables (** Missing HOME or XDG_* environment variables. *)
    | FileError (** File paths are valid, but the files do not exist or file permissions are missing. *)
    | IllFormedFilePath (** File paths are ill-formed (independent of the file system state). *)
    | WebError (** All the network-related errors. *)

    | IllFormedJSON (** Low level JSON parsing errors. *)

    | AnchorNotFound (** Could not find the anchor at the expected library location. *)
    | HijackingAnchor (** Having an anchor on the path to the expected anchor. *)
    | IllFormedAnchor (** The anchor itself is ill-formed. *)

    | InvalidRouter (** The routing table itself is broken. *)
    | LibraryNotFound (** The routing table is okay, but the library cannot be found. *)
    | LibraryConflict (** Conflicting libraries are being loaded. *)
    | UnitNotFound (** Libraries are loaded, but the unit is not found. *)
    | IllFormedUnitPath (** The unit path is ill-formed. *)
    
    | InvalidOCamlPackage (** Invalid OCaml package. *)

  (** Default severity of error codes. See the asai documentation. *)
  let default_severity : t -> Asai.Diagnostic.severity =
    function
    | InvalidRouter -> Bug
    | _ -> Error

  (** String representation of error codes. See the asai documentation. *)
  let short_code : t -> string =
    function _ -> "E0001" (** XXX assign actual code *)
end

include Asai.Reporter.Make(Message)
