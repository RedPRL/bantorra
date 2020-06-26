(** {1 Introduction}

    A resolver that reads the YAML user configuration at [$XDG_CONFIG_HOME/${app_name}/libraries]. Here is an example:
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

    The resolver argument format is either
    {[
      `O ["name", `String name; "version", `String version]
    ]}
    or
    {[
      `O ["name", `String name; "version", `Null]
    ]}

    Versions are compared using structural equality. [null] only matches with [null], not any string. There is no smart comparison or ordering between versions. However, one could have multiple entries as follows:
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

    {1 The Builder}
*)
val resolver : app_name:string -> config:string -> Bantorra.Resolver.t
(** [resolver ~app_name ~config] constructs a resolver based on the user configuration. The location of the user configuration is given by {!val:BantorraBasis.Xdg.get_config_home}. All paths will be normalized and turned into absolute paths using {!val:BantorraBasis.File.normalize_dir}. *)
