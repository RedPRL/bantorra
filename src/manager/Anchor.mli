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
      "resolver": "resolver1",
      "resolver_argument": ...
    },
    {
      "mount_point": ["path", "to", "lib2"],
      "resolver": "resolver2",
      "resolver_argument": ...
    }
  ]
}
    v}

    If the [deps] field is missing, then the library has no dependencies. Each dependency is specified by its mount point in the current library ([mount_point]), the name of the resolver to find the imported library([resolver]), and the argument to the resolver ([resolver_argument]). During the resolution, the entire JSON subtree under the field [resolver_argument] is passed to the resolver. See {!type:Resolver.resolver_argument} and {!val:Resolver.make}.

    The order of entries in [dep] does not matter and the dispatching is based on longest prefix match. If no match can be found, then the unit path is local. The same library can be mounted at multiple points. However, to keep the resolution unambiguous, there cannot be two dependencies sharing the same mount point, and the mount point cannot be the empty list (the root). Here is an example demonstrating the longest prefix match:
    {v
{
  "format": "1.0.0",
  "deps": [
    {
      "mount_point": ["tcp"],
      "resolver": "builtin",
      "resolver_argument": "tcp"
    },
    {
      "mount_point": ["tcp", "bantorra"],
      "resolver": "git",
      "resolver_argument": {
        "url": "https://github.com/RedPRL/bantorra",
        "branch": "main"
      }
    }
  ]
}
    v}

    The unit path [tcp.ftp] will be resolved to the unit [ftp] within the [tcp] library, pending further resolution, while the unit path [tcp.bantorra.connect] will be resolved to [connect] in the library corresponding to [https://github.com/RedPRL/bantorra], not [http.connect] in the [tcp] library. Again, the order of dependencies does not matter because we are performing longest prefix match.

    If some library is mounted at [mylib.hello], then the original unit with the path [mylib.hello] or a path with the prefix [mylib.hello] is no longer accessible. Moreover, [mylib.hello] cannot point to any unit after the mounting because no unit can be associated with the empty path (the root), and [mylib.hello] means the empty path (the root) in the mounted library, which cannot refer to any unit.
*)

(** {1 Types} *)

type t
(** The type of anchors. *)

type unitpath = string list
(** The type of unit paths. *)

type lib_ref =
  { resolver : string (** The name of the library resolver. *)
  ; resolver_argument : Resolver.resolver_argument (** The argument to the resolver. *)
  }
(** The type of library references to be resolved. *)

(** {1 Anchor I/O} *)

val read : string -> t
(** [read path] read the content of an anchor file. *)

(** {1 Accessors} *)

val iter_deps : (lib_ref -> unit) -> t -> unit
(** [iter_lib_refs f a] runs [f] on each dependency listed in the anchor [a]. *)

val dispatch_path : t -> unitpath -> (lib_ref * unitpath) option
(** [dispatch_path a p] resolves the unit path [p] to [Some (ref, p')] if it points to a unit in another library referenced by [ref] and [p'], or [None] if it is a local unit path. The dispatching is done by longest prefix match. *)
