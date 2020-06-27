(** {1 Pure Filename Calculation} *)

val (/) : string -> string -> string
(**
   [p / q] concatenates paths [p] and [q]. The path [q] is assumed to be a relative path.
*)

val join : string list -> string
(**
   The n-ary version of {!val:(/)}
*)

(** {1 Basic I/O} *)

val writefile : string -> string -> unit
(**
   [writefile path str] writes the string [str] the file at [path] (in binary mode).
   If there was already a file at [path], it will be overwritten.
*)

val writefile_noerr : string -> string -> unit
(**
   [writefile_noerr path str] is similar to [writefile path str] except that all exceptions are caught and ignored.
*)

val readfile : string -> string
(**
   [readfile path] reads the content of string [str] the file at [path] (in binary mode).
   If there was already a file at [path], it will be overwritten.
*)

(** {1 Directories} *)

val ensure_dir : string -> unit
(**
   [ensure_dir dir] effectively implements [mkdir dir] in OCaml.
*)

val protect_cwd : (string -> 'a) -> 'a
(**
   [protect_cwd f] runs [f cwd] where [cwd] is the current working directory, and restore the current
   working directory after the computation is done, even when an exception is raised.
*)

val normalize_dir : string -> string
(**
   [normalize_dir dir] uses [Sys.chdir] and [Sys.getcwd] to normalize a path. Symbolic links and special
   directories such as [.] and [..] will be resolved and the result will be an absolute path on many systems.
   The current working directory will be restored after the computation.
*)

(** {1 Locating Files} *)

val is_existing_and_regular : string -> bool
(**
   [is_existing_and_regular path] tests whether [p] points to a regular file (in particular, not a directory).
   Symbolic links are followed before the testing.
*)

val is_existing_and_directory : string -> bool
(**
   [is_existing_and_directory path] tests whether [p] points to a directory.
   Symbolic links are followed before the testing.
*)

val is_executable : string -> bool
(** [is_executable p] checks whether the file at [p] is executable. Does not work on Windows (yet). *)

val locate_anchor : anchor:string -> string -> string * string list
(**
   [locate_anchor ~anchor dir] finds the closest regular file named [anchor] in [dir] or its ancestors
    in the file system tree.
    It returns the first directory that holds the file named [anchor] on the way from [dir] to the root directory,
    along with the relative path from the returned directory to [dir].
    The exception [Not_found] is raised if such a file cannot be found.

    For example, on a typical Linux system, suppose there is no file called [anchor.txt] under directiors
    [/usr/lib/gcc/] and [/usr/lib/], but there is such a file under [/usr/].
    [locate_anchor ~anchor:"anchor.txt" "/usr/lib/gcc"] will return ["/usr", ["lib"; "gcc"]]
    and [locate_anchor ~anchor:"anchor.txt" "/usr"] will return ["/usr", []].
*)

val locate_anchor_ : anchor:string -> string -> string
(**
   [locate_anchor_ ~anchor dir] is the same as [locate_anchor ~anchor dir] except that the second component
    of the returned value is dropped. In other words, only the found directory is returned.
*)
