(** This library implements basic routines used by other libraries. *)

(** {1 Main Modules} *)

module File = File
(** Basic I/O and path manipulation. *)

module Marshal = Marshal
(** Serialization. *)

(**/**)

(** {1 Helper Modules} *)

module Error = Error
(** Generic error reporting functions. *)

module Errors = Errors
(** Specialized error reporting functions. *)

module Util = Util
(** Utility functions. *)

module ResultMonad = ResultMonad
(** The {!type:result} monad. *)
