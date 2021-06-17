(** The waypoint resolver walks around the file system to resolve library names. It tries to find special files (called {e landmarks}) that contain waypoints, which help the resolver to find the roots of target libraries. All landmark files have the same file name specified by the argument given to {!val:resolver}.
*)

(**
   {1 Argument Format}

   The resolver accepts simple JSON strings as library names.
*)

(**
   {1 Waypoints and Landmark Files}

   A waypoint is either {e direct} or {e indirect}. A direct waypoint points to the library root in the file system directly. Its JSON representation is as follows:
   {v
{
  "cool": {
    "at": ["mylib", "cool"]
  }
}
   v}
   This means the root of the [cool] library is at the file system path [mylib/cool]. An indect waypoint is pointing to another waypoint, possibly with a new library name to look up. Its JSON representation is:
   {v
{
  "cool": {
    "next": ["mylib"]
  }
}
   v}
   This means one should look for the landmark file under the [mylib] directory for further instructions. One can also specify the [rename] field in case a new library name should be used:
   {v
{
  "cool.basis": {
    "next": ["cool"],
    "rename": "basis"
  }
}
   v}

   A complete landmark file looks like this:
   {v
{
  "format": "1.0.0",
  "waypoints": {
    "cool.basis": {
      "next": ["path", "to", "another", "directory"],
      "rename": "cool.basis.new"
    },
    "hello": {
      "at": ["vendor", "lib", "hello"]
    }
  }
}
   v}

   There are two phases in locating the library using waypoints. In the first phase, the resolver starts from the root of the library that imports the target library, going up in the file system tree until it finds a landmark file with an applicable waypoint (that is, with a matching field in the [waypoints] JSON object). The resolution fails if no much landmark files are found. If such a landmark file is found, then the resolver enters the second phase. During the second phose, it follow the waypoints until the root of the target library is found. The difference from the first phase is that if the library the resolver is looking for is not explicitly listed in the [waypoints] object, the resolution fails immediately. In comparison, the resolver would climb up the file system tree during the first phase. This is to prevent unintentional infinite looping due to simple typos.
*)

(** {1 The Builder} *)

val resolver : ?eager_resolution:bool -> landmark:string -> Bantorra.Resolver.t
(** [resolver ~eager_resolution ~landmark] construct a resolver for the specified file name [landmark].

    @param eager_resolution Whether full resolution is performed to check the validity of library names. If the value is [false], the resolver will only check whether the argument to the resolver is well-formed. The default value is [false].
    @param landmark The name of the special landmark files that the resolver should look for.
*)

val clear_cached_landmarks : unit -> unit
(** Landmark files are all cached to reduce I/O load, but perhaps you are writing some tool to modify landmark files. In this case, one should call this function to reload all landmark files. *)
