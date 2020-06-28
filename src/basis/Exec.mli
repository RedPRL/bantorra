val system : prog:string -> args:string list -> unit
(** A more usable UnixLabels.system. *)

val with_system_in : prog:string -> args:string list -> (in_channel -> 'a) -> 'a
(** A high-level UnixLabels.open_process_in that will automatically close the channel. *)
