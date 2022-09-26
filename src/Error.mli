(** Algebraic effects of error reporting. *)

include Asai.Logger.S with module Code := ErrorCode
(** @open *)
