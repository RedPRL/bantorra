(** {1 Argument Format}

    The router takes a JSON argument in one of the following formats:
    {v
{
  "name": "bantorra",
  "version": "0.1.0"
}
    v}
    {v
{
  "name": "bantorra",
  "version": null
}
    v}
    {v
{ "name": "bantorra" }
    v}
    A missing [version] is understood as the version [null] (different from the string ["null"]). Therefore, the last two specifications are identical. Versions are compared using structural equality. There is no smart comparison, version globbing, or ordering between versions. Each version is completely independent of each other, and the version [null] is distinct from any string versions.
*)

(** {1 Configuration Format} *)

(**
   By default, the configuration is at [$XDG_CONFIG_HOME/${app_name}/${config}]. The exact path is given by {!val:BantorraBasis.File.get_xdg_config_home} concatenated with the argument [config] given to {!val:router}.

   Here is an example configuration file:
   {v
{
  "format": "1.0.0",
  "libraries": [
    {
      "name": "num",
      "version": "3",
      "at": "/usr/lib/something/num34"
    },
    {
      "name": "tcp",
      "version": "2",
      "at": "/usr/lib/something/tcp21"
    }
  ]
}
   v}

    You can register multiple versions of the same library in the user configuration file, as long as incompatible versions are not {e in use} at the same time. Two versions are compatible if they refer to the same location in the file system. (For example, if both versions ["1.0"] and ["1"] point to [/usr/lib/hello/1.0], then they are compatible and can be used interchangeably.) Any attempt to load incompatible versions during the program execution would abort the library routing.

   {v
{
  "format": "1.0.0",
  "libraries": [
    {
      "name": "tcp",
      "version": "2",
      "at": "/usr/lib/something/tcp21"
    },
    {
      "name": "tcp",
      "version": "2.1",
      "at": "/usr/lib/something/tcp21"
    }
  ]
}
   v}

   {v
{
  "format": "1.0.0",
  "libraries": [
    {
      "name": "tcp",
      "versions": ["2", "2.1"],
      "at": "/usr/lib/something/tcp21"
    }
  ]
}
   v}

   The following is a more complicated example:

   {v
{
  "format": "1.0.0",
  "libraries": [
    {
      "name": "num",
      "versions": ["2", "2.5"],
      "at": "/usr/lib/something/num25"
    },
    {
      "name": "num",
      "version": "3",
      "at": "/usr/lib/something/num34"
    },
    {
      "name": "num",
      "version": ["3.4", null],
      "at": "/usr/lib/something/num34"
    },
    {
      "name": "tcp",
      "version": "2",
      "at": "/usr/lib/something/tcp21"
    },
    {
      "name": "tcp",
      "version": "2.1",
      "at": "/usr/lib/something/tcp21"
    }
  ]
}
    v}

   Given the above configuration file, versions ["2"] and ["2.5"] of the library [num] are compatible because they point to the same location in the file system. Versions [null] and ["2"] of the library ["num"] are not compatible because they point to different locations, and thus they cannot be used at the same time. Note that there is no version [null] registered for the library [tcp], so one has to specify a string version (either ["2"] or ["2.1"]) for it, or the routing would fail. The philosophy is that all entries must be explicitly listed.
*)

(** {1 Builder} *)

val router : ?xdg_macos_as_linux:bool -> app_name:string -> config:string -> Bantorra.Router.t
(** [router ?xdg_as_linux ~app_name ~config] constructs a router that reads the user configuration. The location of the user configuration is given by {!val:BantorraBasis.File.get_xdg_config_home}[?as_linux:xdg_as_linux] concatenated with [config].

    If the configuration file does not exist, an empty mapping is used, which means the router would reject every request.

    @param xdg_as_linux Whether the XDG path construction should follow the Linux convention, ignoring the OS detection.
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

type config
(** The type of configurations as association lists. *)

val default_config : config
(** Default configuration that is empty. *)

val read : ?xdg_macos_as_linux:bool -> app_name:string -> config:BantorraBasis.File.filepath ->
  (config, [> `FormatError of string | `SystemError of string ]) result
(**
   Try to read the configuration file. Note that the results are cached. See {!val:clear_cached_configs}. If the configuration file does not exist, then the default configuration (the empty mapping) is returned. The cache will be updated accordingly.

   @param xdg_as_linux Whether the XDG path construction should follow the Linux convention, ignoring the OS detection.
   @param app_name The application name for generating a suitable directory to put the configuration file.
   @param config The file path of the configuration file.
*)

val lookup : name:string -> version:string option -> config -> BantorraBasis.File.filepath option

val write : ?xdg_macos_as_linux:bool -> app_name:string -> config:string -> config ->
  (unit, [> `FormatError of string | `SystemError of string ]) result
(**
   Write the configuration file.

   The cache within this module will be updated upon successful writing. See {!val:clear_cached_configs}.

   @param xdg_as_linux Whether the XDG path construction should follow the Linux convention, ignoring the OS detection.
   @param app_name The application name for generating a suitable directory to put the configuration file.
   @param config The file name of the configuration file.
*)
