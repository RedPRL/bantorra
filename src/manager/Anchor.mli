(** An anchor is a JSON file pinning the root of a library. *)

(** {1 Format}

    It can be in one of the following formats:
    {v
{ "format": "1.0.0" }
    v}
    {v
{
  "format": "1.0.0",
  "deps": [
    {
      "mount_point": ["path", "to", "lib1"],
      "router": "router1",
      "router_argument": ...
    },
    {
      "mount_point": ["path", "to", "lib2"],
      "router": "router2",
      "router_argument": ...
    }
  ]
}
    v}

    If the [deps] field is missing, then the library has no dependencies. Each dependency is specified by its mount point in the current library ([mount_point]), the name of the router to find the imported library([router]), and the argument to the router ([router_argument]). During the resolution, the entire JSON subtree under the field [router_argument] is passed to the router. See {!type:Router.router_argument} and {!val:Router.make}.

    The order of entries in [dep] does not matter and the dispatching is based on longest prefix match. If no match can be found, then the unit path is local. The same library can be mounted at multiple points. However, to keep the resolution unambiguous, there cannot be two dependencies sharing the same mount point, and the mount point cannot be the empty list (the root). Here is an example demonstrating the longest prefix match:
    {v
{
  "format": "1.0.0",
  "deps": [
    {
      "mount_point": ["tcp"],
      "router": "builtin",
      "router_argument": "tcp"
    },
    {
      "mount_point": ["tcp", "bantorra"],
      "router": "git",
      "router_argument": {
        "url": "https://github.com/RedPRL/bantorra",
        "branch": "main"
      }
    }
  ]
}
    v}

    The unit path [tcp.ftp] will be routed to the unit [ftp] within the [tcp] library, pending further resolution, while the unit path [tcp.bantorra.connect] will be routed to [connect] in the library corresponding to [https://github.com/RedPRL/bantorra], not [http.connect] in the [tcp] library. Again, the order of dependencies does not matter because we are performing longest prefix match.

    If some library is mounted at [mylib.hello], then the original unit with the path [mylib.hello] or a path with the prefix [mylib.hello] is no longer accessible. Moreover, [mylib.hello] cannot point to any unit after the mounting because no unit can be associated with the empty path (the root), and [mylib.hello] means the empty path (the root) in the mounted library, which cannot refer to any unit.
*)

(** {1 Types} *)

type t
(** The type of anchors. *)

type unitpath = string list
(** The type of unit paths. *)

type lib_ref =
  { router : string (** The name of the library router. *)
  ; router_argument : Router.router_argument (** The argument to the router. *)
  }
(** The type of library references to be routed. *)

(** {1 Anchor I/O} *)

val read : string -> (t, [> `FormatError of string | `SystemError of string ]) result
(** [read path] read the content of an anchor file. *)

(** {1 Accessors} *)

val iter_routes : (lib_ref -> (unit, 'e) result) -> t -> (unit, 'e) result

val is_local : t -> unitpath -> bool

val dispatch_path : t -> unitpath -> (lib_ref * unitpath) option
(** [dispatch_path a p] routes the unit path [p] to [Some (ref, p')] if it points to a unit in another library referenced by [ref] and [p'], or [None] if it is a local unit path. The dispatching is done by longest prefix match. *)
