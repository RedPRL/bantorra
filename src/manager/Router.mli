open BantorraBasis

(** {1 Types} *)

type t
(** The type of library routers. *)

type router_argument = Marshal.value
(** The type of arguments to routers. *)

(** {1 The builder} *)

val make :
  ?fast_checker:(starting_dir:string -> router_argument -> bool) ->
  ?args_dumper:(starting_dir:string -> router_argument -> string) ->
  (starting_dir:string -> router_argument -> (File.filepath, [`InvalidLibrary of string]) result) ->
  t
(** [make ?fast_checker ?args_dumper router] creates a new router
    that can be used in {!val:Manager.init}.

    @param router [router ~starting_dir args] is responsible for finding the root of the library specified by [args]. A library manager will feed the router with unparsed [router_arguments] field in an anchor file. (See {!module:Manager}.) The return value is [None] if the resolution fails.
    @param fast_checker A validity checker for dependencies in anchor files when loading a library (before the units from other libraries are actually needed). It is taking the same arguments as the [router] does, but it only needs to predict whether the resolution would be successful. Some library resolution could be expensive (e.g., involving downloading the sources from the server) and a faster, less precise validity checker might be desired. If absent, full resolution will be used as the checker.
    @param args_dumper A hack to dump the arguments as a string for ugly-printing. This will be replaced by proper pretty-printing in the future. If absent, {!val:BantorraBasis.Marshal.dump} is used.
*)

(** {1 Accessors} *)

val route : t -> starting_dir:string -> router_argument -> (File.filepath, [> `InvalidLibrary of string]) result
val route_opt : t -> starting_dir:string -> router_argument -> File.filepath option
val fast_check : t -> starting_dir:string -> router_argument -> bool
val dump_argument : t -> starting_dir:string -> router_argument -> string

(** {1 Error reporting} *)

val library_load_error : ('a, unit, string, ('b, [> `InvalidLibrary of string ]) result) format4 -> 'a
