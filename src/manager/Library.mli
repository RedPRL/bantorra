open BantorraBasis

(** {1 Types} *)

type path = Anchor.path
(** The type of unit paths. *)

type t
(** The type of libraries. *)

(** {1 Initialization} *)

val load_from_root : find_cache:(string -> t option) -> anchor:string -> File.filepath ->
  (t, [> `InvalidLibrary of string ]) result

val load_from_dir : find_cache:(string -> t option) -> anchor:string -> File.filepath ->
  (t * path option, [> `InvalidLibrary of string ]) result

val load_from_unit : find_cache:(string -> t option) -> anchor:string -> File.filepath -> suffix:string ->
  (t * path option, [> `InvalidLibrary of string ]) result

(** {1 Accessor} *)

val root : t -> File.filepath

val iter_routes :
  (router:string -> router_argument:Marshal.value -> (unit, 'e) result) ->
  t -> (unit, 'e) result

(** {1 Hook for Library Managers} *)

(** The following API is for a library manager to chain all the libraries together.
    Please use the high-level API in {!module:Manager} instead. *)

val resolve :
  depth:int ->
  global:(depth:int ->
          router:string ->
          router_argument:Marshal.value ->
          starting_dir:File.filepath ->
          path ->
          suffix:string ->
          (t * path * File.filepath, [> `UnitNotFound of string] as 'e) result) ->
  t -> path -> suffix:string -> (t * path * File.filepath, 'e) result
