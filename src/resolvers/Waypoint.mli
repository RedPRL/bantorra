(** {1 Introduction}

    The waypoint resolver walks around the file system to resolve the library name. It tries to find special files (called {e landmarks}) that contain waypoints. Landmarks all have the same file name specified by the argument given to {!val:resolver}, which are similar to anchors of libraries.

    The resolver argument format is
    {[
      `String name
    ]}
    or, in terms of YAML, a simple string.

    A waypoint is either {e direct} or {e indirect}. A direct waypoint points to the library root directly. Its YAML representation is as follows:
    {v
cool:
  at: [mylib, cool]
    v}
    This means the root of the [cool] library is at [mylib/cool]. An indect waypoint is pointing to another waypoint, possibly with a new library name to look up. Its YAML representation is:
    {v
cool:
  next: [mylib]
    v}
    This means one should look for the landmark file under the [mylib] directory for further instructions. One can also specify the [rename] field in case a new library name should be used:
    {v
cool.basis:
  next: [cool]
  rename: basis
    v}

    A complete landmark file looks like this:
    {v
format: "1.0.0"
waypoints:
  cool.basis:
    next: [cool]
    rename: basis
  hello:
    at: [misc, hello]
    v}

    The resolver starts from the root of the library that imports the target library, going up in the file system tree until it finds a landmark file with an applicable waypoint. It will then follow the waypoints until the root of the target library is found. Note that the resolver only climbs up the file system tree once, at the beginning. The resolution immediately fails if an indirect waypoint points to a landmark file with no applicable waypoint. This would prevent unintentional infinite looping due to simple typos.

    {1 The Builder}
*)

val resolver : strict_checking:bool -> landmark:string -> Bantorra.Resolver.t
(** [resolver ~strict_checking ~landmark] construct a resolver for the specified file name [landmark].

    @param strict_checking Whether one should perform full resolution to check the validity of library names. If absent or [false], the resolver will only check whether all dependencies are well-formed when loading a new library.
    @param landmark The name of the special landmark files that the resolver should look for.
*)

val clear_cached_landmarks : unit -> unit
(** Landmark files are all cached to reduce I/O load, but perhaps you are writing some tool to modify landmark files. In this case, one should call this function to reload all landmark files. *)
