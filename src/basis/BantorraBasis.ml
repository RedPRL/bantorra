(** This library implements basic routines used by other libraries. *)

module ResultMonad = ResultMonad

module File = File
(** Routines to handle file paths and basic I/O. *)

module Exec = Exec
(** Routines for running external tools. *)

module Marshal = Marshal
(** Routines for serialization. *)

module Xdg = Xdg
(** Routines to calculate the directories in the XDG standard
    while having reasonable default values on major platforms. *)

module Util = Util
(** Other routines that are difficult to classify. *)
