open BantorraLibrary

(** {1 Types} *)

type t
(** The type of library resolvers. *)

type res_args = Anchor.res_args
(** The type of arguments to resolvers. *)

(** {1 Builders} *)

val make :
  ?fast_checker:(cur_root:string -> res_args -> bool) ->
  ?args_dumper:(cur_root:string -> res_args -> string) ->
  (cur_root:string -> res_args -> string option) ->
  t
(** [make ?fast_checker ?args_dumper resolver] creates a new resolver
    that can be used in {!val:Manager.init}.

    @param fast_checker An alternative validity checker for arguments. Some library resolution could be expensive (e.g., involving downloading the sources from the server) and a fast validity checker might be desired. If absent, a full resolution is conducted as the checker.
    @param args_dumper A hack to dump the arguments as a string for ugly-printing. This will be replaced by proper pretty-printing in the future. If absent, {!val:BantorraBasis.Marshal.dump} is used.
*)

(** {1 Accessors} *)

val resolve : t -> cur_root:string -> res_args -> string
val resolve_opt : t -> cur_root:string -> res_args -> string option
val fast_check : t -> cur_root:string -> res_args -> bool
val dump_args : t -> cur_root:string -> res_args -> string
