open BantorraBasis

(** {1 Types} *)

type t
(** The type of library routers. *)

type argument = Marshal.value
(** The type of arguments to routers. *)

(** {1 The builder} *)

val make :
  ?fast_checker:(starting_dir:string -> arg:argument -> bool) ->
  (starting_dir:string -> arg:argument -> (File.filepath, [`InvalidLibrary of string]) result) ->
  t
(** [make ?fast_checker route] creates a new router that can be used in {!val:Manager.init}.

    @param route [route ~starting_dir ~arg] is responsible for finding the root of the library specified by [arg]. A library manager will feed the router with unparsed [router_argument] field in an anchor file. (See {!module:Manager}.)
    @param fast_checker A validity checker for dependencies in anchor files when loading a library (before the units from other libraries are actually needed). It is taking the same arguments as the [router] does, but it only needs to check whether the resolution could have been successful. Some library resolution is expensive (e.g., involving downloading the sources from the server) and a faster, incomplete validity checker might be desirable. If absent, [route] will be used as the checker.
*)

(** {1 Accessors} *)

val route : t -> starting_dir:string -> arg:argument -> (File.filepath, [> `InvalidLibrary of string]) result
val fast_check : t -> starting_dir:string -> arg:argument -> bool
