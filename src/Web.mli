(** Web utility functions. *)

val get : ?follow_redirects:bool -> string -> string
(** [get url] returns the body of the response of HTTP GET at [url].

    @param follow_redirects Whether to follow redirections such as HTTP 301 and 203. [true] by default.
*)

val is_online : unit -> bool
(** Check connectivity using Firefox's detection of captive portals. See {:https://firefox-source-docs.mozilla.org/networking/captive_portals.html}. *)
