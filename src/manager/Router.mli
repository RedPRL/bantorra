open BantorraBasis

(** {1 Types} *)

type param = Marshal.value
(** The type of parameters to routers. *)

type t = param -> File.path
(** The type of library routers. *)

type pipe = param -> param

val get_lib_root : unit -> FilePath.t

(**/**)

val run : lib_root:FilePath.t -> (unit -> 'a) -> 'a
