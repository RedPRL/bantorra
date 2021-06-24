(** The waypoint router walks around the file system to route library names. It tries to find special files (called {e landmarks}) that contain waypoints, which help the router to find the roots of target libraries. All landmark files have the same file name specified by the argument given to {!val:router}.
*)

(**
   {1 Argument Format}

   The router accepts simple JSON strings as library names.
*)

(**
   {1 Waypoints and Landmark Files}

   A waypoint is either {e direct} or {e indirect}. A direct waypoint points to the library root in the file system directly. Its JSON representation is as follows:
   {v
{
  {
    "name": "cool",
    "at": "mylib/cool/"
  }
}
   v}
   This means the root of the [cool] library is at the file system path [mylib/cool/]. An indirect waypoint is pointing to another waypoint, possibly with a new library name to look up. Its JSON representation is:
   {v
{
  {
    "name": "cool",
    "next_waypoint": "mylib/"
  }
}
   v}
   This means one should look for the landmark file under the [mylib/] directory for further instructions. One can also specify the [rename] field in case a new library name should be used:
   {v
{
  {
    "name": "cool.basis"
    "next_waypoint": "cool/",
    "next_as": "basis"
  }
}
   v}

   A complete landmark file looks like this:
   {v
{
  "format": "1.0.0",
  "waypoints": [
    {
      "name": "cool.basis",
      "next_waypoint": "path/to/another/directory/",
      "next_as": "cool.basis.new"
    },
    {
      "name": "hello",
      "at": "vendor/lib/hello/"
    }
  ]
}
   v}

   There are two phases in locating the library using waypoints. In the first phase, the router starts from the root of the library that imports the target library, going up in the file system tree until it finds a landmark file with an applicable waypoint (that is, with a matching field in the [waypoints] JSON object). The resolution fails if no much landmark files are found. If such a landmark file is found, then the router enters the second phase. During the second phase, it follow the waypoints until the root of the target library is found. The difference from the first phase is that if the library the router is looking for is not explicitly listed in the [waypoints] object, the resolution fails immediately. In comparison, the router would climb up the file system tree during the first phase. This is to prevent unintentional infinite looping due to simple typos.
*)

(** {1 The Builder} *)

val router : ?max_depth:int -> ?eager_resolution:bool -> landmark:string -> Bantorra.Router.t
(** [router ?eager_resolution ~landmark] construct a router for the specified file name [landmark].

    @param max_depth Maximum depth in resolving indirect waypoints. The default value is [100].
    @param eager_resolution Whether full resolution is performed to check the validity of library names. If the value is [false], the router will only check whether the argument to the router is well-formed. The default value is [false].
    @param landmark The name of the special landmark files that the router should look for.
*)

val clear_cached_landmarks : unit -> unit
(** Landmark files are all cached to reduce I/O load, but perhaps you are writing some tool to modify landmark files. In this case, one should call this function to reload all landmark files. *)
