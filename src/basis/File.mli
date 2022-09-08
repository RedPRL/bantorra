(** {1 Path types} *)

type path = FilePath.t

(** {1 Basic I/O} *)

val write : path -> string -> unit
(**
   [write path str] writes the string [str] the file at [path] (in binary mode).
   If there was already a file at [path], it will be overwritten.
*)

val read : path -> string
(**
   [read path] reads the content of string [str] the file at [path] (in binary mode).
   If there was already a file at [path], it will be overwritten.
*)

(** {1 Directories} *)

val get_cwd : unit -> path

val create_dir : path -> bool
(**
   [create_dir dir] effectively implements [mkdir dir] in OCaml. Returns [true] if the directory is newly created.
*)

(** {1 Locating Files} *)

val file_exists : path -> bool

val locate_anchor : anchor:string -> path -> path * UnitPath.t
(**
   [locate_anchor ~anchor dir] finds the closest regular file named [anchor] in [dir] or its ancestors in the file system tree.

   @param dir The starting directory. It will be normalized with respect to the current working director.

   @return
   (1) the first directory that holds a regular file named [anchor] on the way from [dir] to the root directory; and (2) the relative path from the returned directory to [dir].

   For example, on a typical Linux system, suppose there is no file called [anchor.txt] under directiors
   [/usr/lib/gcc/] and [/usr/lib/], but there is such a file under [/usr/].
   [locate_anchor ~anchor:"anchor.txt" "/usr/lib/gcc"] will return ["/usr", ["lib"; "gcc"]]
   and [locate_anchor ~anchor:"anchor.txt" "/usr"] will return ["/usr", []].
*)

val locate_hijacking_anchor : anchor:string -> root:path -> UnitPath.t -> path option

(** {1 Special Directories} *)

val get_home : unit -> path

val expand_home : path -> path
(** Expand the beginning tilde to the home directory. *)

val get_xdg_config_home : app_name:string -> path
(** Get the per-user config directory based on [XDG_CONFIG_HOME]
    with reasonable default values on major platforms. *)

val get_xdg_cache_home : app_name:string -> path
(** Get the per-user persistent cache directory based on [XDG_CACHE_HOME]
    with reasonable default values on major platforms. *)
