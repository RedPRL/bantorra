(** The Bantorra library manager. *)

(** {1 Main Modules} *)

module Manager = Manager
(** Library managers. *)

module Router = Router
(** Routers. *)

module ErrorCode = ErrorCode
(** Error codes. *)

module Error = Error
(** Algebraic effects of error reporting. *)

(** {1 Helper Modules} *)

module UnitPath = UnitPath
(** Unit paths. *)

module FilePath = FilePath
(** Basic path manipulation. *)

module File = File
(** Basic I/O. *)

module Marshal = Marshal
(** JSON Serialization. *)
