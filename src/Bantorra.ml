(**
   A {e library} in the Bantorra framework is a tree of units that can be accessed via unit paths from the root. A unit path is a list of strings, such as [std/num/types]. The purpose of the Bantorra framework is to provide a flexible mechanism to map each unit path to some underlying file path. For example, the unit path [std/num/types] might be mapped to the file path [/usr/lib/cool/number/types.data], and the resolution process takes in both what is set up by the application and what is provided by its users.
*)

(**
   {1 Introduction}

   In the simplest case, there is a one-to-one correspondence between units and files under a directory: the unit path [a/b/c] corresponds to the file [a/b/c.data] where [.data] is the extension specified by the application. The root directory is marked by a special file called {e anchor}, which is a file with a fixed name again specified by the application. For example, the existence of a [dune] file means there is an OCaml library in the eyes of the [dune] building tool. An anchor in the Bantorra framework marks the root of a library. For example, if the anchor file name is [.lib], the file at [/usr/lib/cool/number/.lib] indicates that there is a library containing files under [/usr/lib/cool/number].

   It is common for units within a library to access units in another library. To do so, an anchor may {e mount} another library in the tree, in a way similar to how partitions are mounted in POSIX-compliant systems. Here is a sample anchor file:
   {v
{
  "format": "1.0.0",
  "mounts": [
    "std/num": ["local", "/usr/lib/cool/number"]
  ]
}
    v}
   The above anchor file mounts the library [number] at [std/num]. With this, the unit path [std/num/types] will be routed to the unit [types] within the library [number]. The resolution is recursive because the mounted library may mount yet another library. The actual interpretation of [["local", "/usr/lib/cool/number"]] is fully controlled by the application---the example assumes that [["local", path]] is understood as a local [path], but any OCaml function from JSON data to directory paths can be used. A few basic routing functions are provided in {!module:Router}. *)

(** {1 Format of Anchors}

    An anchor can be in one of the following formats:
    {v
{ "format": "1.0.0" }
    v}
    {v
{
  "format": "1.0.0",
  "mounts": [
    "path/to/lib1": ...
    "path/to/lib2": ...
  ]
}
    v}

    If the [mounts] field is missing, then the library has no dependencies. Each dependency is specified by its mount point ([mount_point]), the name of the router to find the imported library ([router]), and the argument to the router ([router_argument]). During the resolution, the entire JSON subtree under the field [router_argument] is passed to the router. See {!type:Router.argument} and {!val:Router.make}.

    The order of entries in [mounts] does not matter because the dispatching is based on longest prefix match. If no match can be found, then it means the unit path refers to a local unit. The same library can be mounted at multiple points. However, to keep the resolution unambiguous, there cannot be two libraries mounted at the same point. Here is an example demonstrating the longest prefix match:
    {v
{
  "format": "1.0.0",
  "mounts": [
    "lib": "stdlib",
    "lib/bantorra": ["git", {url: "https://github.com/RedPRL/bantorra"}]
  ]
}
    v}

    The unit path [world.orntorra] will be routed to the unit [orntorra] within the [world] library, pending further resolution (as the [world] library might further mount other libraries), while the unit path [world.bantorra.shisho] will be routed to [shisho] in the library corresponding to [https://github.com/RedPRL/bantorra], not the unit [bantorra.shisho] in the [world] library.

    If some library is mounted at [world.towitorra], then the original unit with the path [world.towitorra] or a path with the prefix [world.towitorra] is no longer accessible. Moreover, [world.towitorra] cannot point to any unit after the mounting because no unit can be associated with the empty path (the root), and [world.towitorra] means the empty path (the root) in the mounted library, which cannot refer to any unit.
*)

(** {1 Main Modules} *)

module Manager = Manager
(** Library managers. *)

module Router = Router
(** Routers. *)

module ErrorCode = ErrorCode
(** Error codes. *)

module Error = Error
(** Algebraic effects of error reporting. *)

(** {1 Helper Modules} *)

module UnitPath = UnitPath
(** Unit paths. *)

module FilePath = FilePath
(** Basic path manipulation. *)

module File = File
(** Basic I/O. *)

module Marshal = Marshal
(** JSON Serialization. *)
