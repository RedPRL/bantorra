type filepath = string

(** {1 Pure Filename Calculation} *)

val (/) : filepath -> filepath -> filepath
(**
   [p / q] concatenates paths [p] and [q].
*)

val join : filepath list -> filepath
(**
   The n-ary version of {!val:(/)}
*)

(** {1 Basic I/O} *)

val writefile : filepath -> string -> (unit, [> `SystemError of string]) result
(**
   [writefile path str] writes the string [str] the file at [path] (in binary mode).
   If there was already a file at [path], it will be overwritten.
*)

val readfile : filepath -> (string, [> `SystemError of string]) result
(**
   [readfile path] reads the content of string [str] the file at [path] (in binary mode).
   If there was already a file at [path], it will be overwritten.
*)

(** {1 Directories} *)

val getcwd : unit -> filepath

val chdir : filepath -> (unit, [> `SystemError of string]) result

val ensure_dir : filepath -> (unit, [> `SystemError of string]) result
(**
   [ensure_dir dir] effectively implements [mkdir dir] in OCaml.
*)

val protect_cwd : (filepath -> 'a) -> 'a
(**
   [protect_cwd f] runs [f cwd] where [cwd] is the current working directory, and then restores the current
   working directory after the computation is done.
*)

val normalize_dir : filepath -> (filepath, [> `SystemError of string]) result
(**
   [normalize_dir dir] uses [Sys.chdir] and [Sys.getcwd] to normalize a path.
   The result will be an absolute path free of [.], [..], and symbolic links on many systems.
*)

val parent_of_normalized_dir : filepath -> filepath option
(**
   [parent_of_normalized_dir dir] calculates the parent of a normalized directory [dir]. If [dir] is already the root directory, then this function returns [None]; otherwise it returns [Some parent] where [parent] is the parent directory. The result could be wrong if [dir] was not already normalized.
*)

(** {1 Locating Files} *)

val file_exists : filepath -> bool

val locate_anchor : anchor:string -> filepath -> (filepath * string list, [> `AnchorNotFound of string]) result
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

val hijacking_anchors_exist : anchor:string -> root:filepath -> string list -> bool

(** {1 Special Directories} *)

val get_home : unit -> filepath option

val expand_home : filepath -> filepath
(** Expand the beginning tilde to the home directory. *)

val get_xdg_config_home : ?macos_as_linux:bool -> app_name:string -> (filepath, [> `SystemError of string]) result
(** Get the per-user config directory based on [XDG_CONFIG_HOME]
    with reasonable default values on major platforms. *)

val get_xdg_cache_home : ?macos_as_linux:bool -> app_name:string -> (filepath, [> `SystemError of string]) result
(** Get the per-user persistent cache directory based on [XDG_CACHE_HOME]
    with reasonable default values on major platforms. *)

(** {1 Getting User Inputs} *)
val input_absolute_dir : ?starting_dir:filepath -> string -> (filepath, [> `SystemError of string]) result
val input_relative_dir : string -> filepath
