open BantorraBasis

(** {1 Types} *)

type t
(** The type of libraries. *)

(** {1 Initialization} *)

val load_from_root : version:string -> find_cache:(FilePath.t -> t option) -> anchor:string -> File.path -> t

val load_from_dir : version:string -> find_cache:(FilePath.t -> t option) -> anchor:string -> File.path -> t * UnitPath.t option

val load_from_unit : version:string -> find_cache:(FilePath.t -> t option) -> anchor:string -> File.path -> suffix:string -> t * UnitPath.t option

(** {1 Accessors} *)

val root : t -> File.path

(** {1 Hook for Library Managers} *)

(** The following API is for a library manager to chain all the libraries together.
    Please use the high-level API in {!module:Manager} instead. *)

val resolve :
  depth:int ->
  global:(depth:int ->
          lib_root:File.path ->
          Router.param ->
          UnitPath.t ->
          suffix:string ->
          t * UnitPath.t * File.path) ->
  t -> UnitPath.t -> suffix:string -> t * UnitPath.t * File.path
