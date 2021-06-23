val system : prog:string -> args:string list ->
  (unit, [> `SystemError of string]) result
(** A more structured {!val:UnixLabels.system}. *)

val with_system_in : prog:string -> args:string list -> (in_channel -> 'a) ->
  ('a, [> `SystemError of string]) result
(** A higher-level interface to {!val:UnixLabels.open_process_in} that will automatically close the channel. *)
