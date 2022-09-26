(** Set up the effect handler of error messages. See the documentation of Asai. *)
module Terminal = Asai_unix.Make(Bantorra.ErrorCode)
let run_bantorra f = Bantorra.Error.run f
    ~emit:Terminal.display ~fatal:(fun d -> Terminal.display d; failwith "error")

open Bantorra

(** Get the current working directory. *)
let cwd = run_bantorra File.get_cwd

(** Create the router.

    This router will route [["file", path]] to file [path] and
    [["git", git_params]] to the git repo specified by [git_params],
    placing cloned git repositories under the directory [_build/git].
*)
let router = run_bantorra @@ fun () ->
  (* This is for calculating the absolute path to [_build/git]. *)
  let current_lib_root, _ = File.locate_anchor ~anchor:"anchor.json" cwd in
  Router.dispatch @@
  function
  | "file" -> Option.some @@
    Router.file ?relative_to:(Router.get_starting_dir ()) ~expanding_tilde:true
  | "git" -> Option.some @@
    Router.git (FilePath.of_string ~relative_to:current_lib_root "./_build/git")
  | _ -> None

(** Get a library manager. *)
let manager = run_bantorra @@ fun () -> Manager.init ~version:"1.0.0" ~anchor:"anchor.json" router

(** Load the library where the current directory belongs. *)
let lib_cwd, _ = run_bantorra @@ fun () -> Manager.load_library_from_cwd manager

(** Load a library using the router. *)
let lib_number =
  run_bantorra @@ fun () ->
  Manager.load_library_from_route manager
    (* The argument sent to the router, as a JSON value. *)
    (`A [`String "file"; `String "./lib/number"])
    (* Use the current directory as the starting directory (or the relative paths will fail). *)
    ~starting_dir:cwd

(** Directly load the library from its root without using any routing.
    (The manager will return the same library as [lib_number].) *)
let lib_number2 =
  run_bantorra @@ fun () ->
  Manager.load_library_from_root manager @@
  FilePath.of_string ~relative_to:cwd "./lib/number/"

(** Directly load a remote git repository. *)
let lib_bantorra =
  run_bantorra @@ fun () ->
  Manager.load_library_from_route manager @@
  `A [`String "git"; `O ["url", `String "https://github.com/RedPRL/bantorra"; "path", `String "test/lib/number/"]]

(** Show where the cloned git repository is. *)
let () =
  run_bantorra @@ fun () ->
  Format.printf "Git repo downloaded at %a@." (FilePath.pp ~relative_to:cwd) (Manager.library_root lib_bantorra)

(** Resolve a unit path and get its location in the file system. *)
let _local_lib, _local_path, filepath1 =
  run_bantorra @@ fun () ->
  Manager.resolve manager lib_number (UnitPath.of_string "types") ~suffix:".data"

(** Resolve the same unit path but with a different suffix. *)
let _local_lib, _local_path, filepath2 =
  run_bantorra @@ fun () ->
  Manager.resolve manager lib_number (UnitPath.of_string "types") ~suffix:".compiled"

(** Resolve another unit path and get its location in the file system.
    The result is the same as above, assuming that the library [lib_number]
    is mounted at [std/num], for example using the following anchor file:

    {v
{
  "format": "1.0.0",
  "mounts": { "std/num": ["file", "./lib/number"] }
}
    v}
*)
let _local_lib, _local_path, filepath3 =
  run_bantorra @@ fun () ->
  Manager.resolve manager lib_cwd (UnitPath.of_string "std/num/types") ~suffix:".compiled"

let () =
  run_bantorra @@ fun () ->
  assert (FilePath.equal filepath1 (FilePath.of_string ~relative_to:cwd "./lib/number/types.data"))

let () =
  run_bantorra @@ fun () ->
  assert (FilePath.equal filepath2 (FilePath.of_string ~relative_to:cwd "./lib/number/types.compiled"))

let () =
  run_bantorra @@ fun () ->
  assert (FilePath.equal filepath3 (FilePath.of_string ~relative_to:cwd "./lib/number/types.compiled"))
