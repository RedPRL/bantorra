(** This library implements basic routines used by other libraries. *)

(** {1 Main Modules} *)

module UnitPath = UnitPath
(** Unit paths. *)

module FilePath = FilePath
(** Basic path manipulation. *)

module File = File
(** Basic I/O. *)

module Marshal = Marshal
(** Serialization. *)

(** {1 Error Handling} *)

module ErrorCode = ErrorCode
(** Error codes. *)

module Error = Error
(** Error reporting. *)
