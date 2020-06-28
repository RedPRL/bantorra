(** {1 Types} *)

type t
(** The type of library resolvers. *)

type res_args = BantorraBasis.Marshal.value
(** The type of arguments to resolvers. *)

(** {1 The Builder} *)

val make :
  ?fast_checker:(cur_root:string -> res_args -> bool) ->
  ?args_dumper:(cur_root:string -> res_args -> string) ->
  (cur_root:string -> res_args -> string option) ->
  t
(** [make ?fast_checker ?args_dumper resolver] creates a new resolver
    that can be used in {!val:Manager.init}.

    @param resolver [resolver ~cur_root args] is responsible for finding the root of the library specified by [args]. A library manager will feed the resolver with unparsed [res_args] field in an anchor file. (See {!module:Manager}.) The return value is [None] if the resolution fails.
    @param fast_checker A validity checker for dependencies in anchor files when loading a library (before the units from other libraries are actually needed). It is taking the same arguments as the [resolver] does, but it only needs to predict whether the resolution would be successful. Some library resolution could be expensive (e.g., involving downloading the sources from the server) and a faster, less precise validity checker might be desired. If absent, full resolution will be used as the checker.
    @param args_dumper A hack to dump the arguments as a string for ugly-printing. This will be replaced by proper pretty-printing in the future. If absent, {!val:BantorraBasis.Marshal.dump} is used.
*)

(** {1 Accessors} *)

val resolve : t -> cur_root:string -> res_args -> string
val resolve_opt : t -> cur_root:string -> res_args -> string option
val fast_check : t -> cur_root:string -> res_args -> bool
val dump_args : t -> cur_root:string -> res_args -> string
