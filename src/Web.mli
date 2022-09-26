(** Web utility functions. *)

val get : string -> string
(** [get url] returns the body of the response of HTTP Get at [url]. *)

val is_online : unit -> bool
(** Check connectivity using Firefox's detection of captive portals. See {:https://firefox-source-docs.mozilla.org/networking/captive_portals.html}. *)
