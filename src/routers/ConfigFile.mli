(** Reading user configuration files. *)

(** {1 Builder} *)

(** {1 Configuration I/O} *)

open BantorraBasis

val read : version:string -> FilePath.t -> (Marshal.value, Marshal.value) Hashtbl.t
(** [read_config ~version path] reads the configuration file at [path] and parse it as a rewrite table. *)

val write : version:string -> FilePath.t -> (Marshal.value, Marshal.value) Hashtbl.t -> unit
(** [write_config ~version path table] writes table to the file at [path]. *)
