val get_config_home : ?as_linux:bool -> app_name:string -> string
(** Get the per-user config directory based on [XDG_CONFIG_HOME]
    with reasonable default values on major platforms. *)

val get_cache_home : ?as_linux:bool -> app_name:string -> string
(** Get the per-user persistent cache directory based on [XDG_CACHE_HOME]
    with reasonable default values on major platforms. *)
