
(** {1 Argument Format}

    The resolver takes YAML arguments in one of the following formats:
    {v
name: "bantorra"
verson: "0.1.0"
    v}
    {v
name: "bantorra"
verson: null
    v}
    {v
name: "bantorra"
    v}
    A missing version is understood as the version [null]. Therefore, the last two specifications are identical. Versions are compared using structural equality. There is no smart comparison, version globbing, or ordering between versions. Each version is completely independent of each other; the version [null] only matches [null], not any string version. Not even the string ["null"].

    However, one could have multiple versions of the same library registered in the user configuration file, as long as the versions {e in use} all point to the same library on disk. (For example, one may have both versions ["1.0"] and ["1"] pointing to [/usr/lib/hello/1.0], which means they can be used interchangeably.) Any attempt to load incompatible versions during the program execution would abort the library resolution.

*)

(** {1 Configeration Format} *)

(**
   By default, the configuration is at [$XDG_CONFIG_HOME/${app_name}/${config}]. The exact path is given by {!val:BantorraBasis.Xdg.get_config_home} concatenated with the argument [config] given to {!val:resolver}.

   Here is an example configuration file:
   {v
format: "1.0.0"
libraries:
- name: num
  version: "3"
  at: "/usr/lib/something/num34"
- name: tcp
  version: "2"
  at: "/usr/lib/something/tcp21"
   v}

   Multiple versions of the same library name can be registered to enable dispatching on different versions. Right now, no globbing or smart comparison is supported, so one has to list every possible version of a library in use, including the [null] version. The following is a more complicated configuration file using this dispatching feature:

   {v
format: "1.0.0"
libraries:
- name: num
  version: "2"
  at: "/usr/lib/something/num25"
- name: num
  version: "2.5"
  at: "/usr/lib/something/num25"
- name: num
  version: "3"
  at: "/usr/lib/something/num34"
- name: num
  version: "3.4"
  at: "/usr/lib/something/num34"
- name: num
  version: null
  at: "/usr/lib/something/num34"
- name: tcp
  version: "2"
  at: "/usr/lib/something/tcp21"
- name: tcp
  version: "2.1"
  at: "/usr/lib/something/tcp21"
    v}

   Given this configuration file, versions ["2"] and ["2.5"] of the library [num] are compatible because they point to the same library on disk. Versions [null] and ["2"] of the library ["num"] are not compatible because they point to different libraries. Incompatible libraries cannot be loaded at the same time. Note that there is no version [null] registered for the library [tcp], so one has to specify a string version (either ["2"] or ["2.1"]) for it. The philosophy is that all entries must be explicitly listed.
*)

(** {1 Builder} *)

val resolver : app_name:string -> config:string -> Bantorra.Resolver.t
(** [resolver ~app_name ~config] constructs a resolver that reads the user configuration. The location of the user configuration is given by {!val:BantorraBasis.Xdg.get_config_home} concatenated with [config]. All paths are normalized and turned into absolute paths with respect to the current working directory using {!val:BantorraBasis.File.normalize_dir} .

    If the configuration file does not exist, an empty mapping is used, which means the resolver would reject every request.

    @param app_name The application name for generating a suitable directory to put the configuration file.
    @param config The file name of the configuration file.
*)

val clear_cached_configs : unit -> unit
(** Configuration files are all cached to reduce I/O load, but perhaps you are bypassing this module to modify them. In that case, one should call this function to force rereading configuration files. *)

(** {1 Configuration I/O} *)

type versioned_library =
  { name : string
  ; version : string option
  }
(** The type of versioned library names. [None] corresponds to [null] and [Some ver] corresponds to explicit versions. *)

type config = {dict : (versioned_library * string) list}
(** The type of configurations as association lists. *)

val default_config : config
(** Default configuration that is empty. *)

val read : app_name:string -> config:string -> config
(**
   Try to read the configuration file. Note that the results are cached. See {!val:clear_cached_configs}. If the configuration file does not exist or is ill-formated, then the default configuration (the empty mapping) is returned. The cache will be updated accordingly.

   @param app_name The application name for generating a suitable directory to put the configuration file.
   @param config The file name of the configuration file.
*)

val unsafe_write : app_name:string -> config:string -> config -> unit
(**
   Write the configuration file. Do not use this function unless you know what you are doing. Due to some questionable design of the underlying OCaml YAML package [yaml], strings such as ["1.0"] and ["null"] will not be serialized correctly. It is thus recommended to edit the configuration files directly before the package [yaml] is either fixed or replaced. See the {{:https://github.com/avsm/ocaml-yaml/issues/39}issue on GitHub}.

   The cache within this module will be updated upon successful writing. See {!val:clear_cached_configs}. However, the caveat in the package [yaml] means the written configuration file might be broken or different upon rereading.

   @param app_name The application name for generating a suitable directory to put the configuration file.
   @param config The file name of the configuration file.
*)
