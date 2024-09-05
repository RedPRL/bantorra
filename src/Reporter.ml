module Message =
struct
  (** Type of error codes. See the asai documentation. *)
  type t =

    (* Errors from the system environment *)

    | SystemError (** Generic system errors. *)
    | MissingEnvironmentVariables (** Missing HOME or XDG_* environment variables. *)
    | FileError (** File paths are valid, but the files do not exist or file permissions are missing. *)
    | IllFormedFilePath (** File paths are ill-formed (independent of the file system state). *)
    | WebError (** All the network-related errors. *)
    | InvalidOCamlPackage (** Invalid OCaml package. *)

    (* Errors from parser *)

    | IllFormedJSON (** Low level JSON parsing errors. *)

    (* Errors about anchors *)

    | AnchorNotFound (** Could not find the anchor at the expected library location. *)
    | HijackingAnchor (** Having an anchor on the path to the expected anchor. *)
    | IllFormedAnchor (** The anchor itself is ill-formed. *)

    (* Errors about resolving *)

    | InvalidRouter (** The routing table itself is broken. *)
    | LibraryNotFound (** The routing table is okay, but the library cannot be found. *)
    | LibraryConflict (** Conflicting libraries are being loaded. *)
    | UnitNotFound (** Libraries are loaded, but the unit is not found. *)
    | IllFormedUnitPath (** The unit path is ill-formed. *)

  (** Default severity of error codes. See the asai documentation. *)
  let default_severity : t -> Asai.Diagnostic.severity =
    function
    | InvalidRouter -> Bug
    | _ -> Error

  (** String representation of error codes. See the asai documentation. *)
  let short_code : t -> string =
    function
    | SystemError -> "E0001"
    | MissingEnvironmentVariables -> "E0002"
    | IllFormedFilePath -> "E0003"
    | FileError -> "E0004"
    | WebError -> "E0005"
    | InvalidOCamlPackage -> "E0006"

    | IllFormedJSON -> "E0101"

    | AnchorNotFound -> "E0201"
    | HijackingAnchor -> "E0202"
    | IllFormedAnchor -> "E0203"

    | InvalidRouter -> "E0301"
    | LibraryNotFound -> "E0302"
    | LibraryConflict -> "E0303"
    | IllFormedUnitPath -> "E0304"
    | UnitNotFound -> "E0305"
end

include Asai.Reporter.Make(Message)
