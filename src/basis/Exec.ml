module U = UnixLabels
module E = Errors
open ResultMonad.Syntax

let system ~prog ~args =
  let src = "Exec.system" in
  let cmd = Filename.quote_command prog args in
  match U.system cmd with
  | U.WEXITED 0 -> ret ()
  | U.WEXITED i ->
    E.error_system_msgf ~src "The command `%s' exited with the code %i" cmd i
  | U.WSIGNALED i ->
    E.error_system_msgf ~src "The command `%s' was interrupted by the signal %i" cmd i
  | U.WSTOPPED i ->
    E.error_system_msgf ~src "The command `%s' was stopped by the signal %i" cmd i
  | exception U.Unix_error (e, _, _) ->
    E.error_system_msg ~src @@ U.error_message e

let with_system_in ~prog ~args f =
  let src = "Exec.system_in" in
  let cmd = Filename.quote_command prog args in
  let* ic =
    let rec loop () =
      try ret @@ U.open_process_in cmd
      with
      | U.Unix_error (U.EINTR, _, _) -> loop ()
      | U.Unix_error (e, _, _) ->
        E.error_system_msg ~src @@ U.error_message e
    in
    loop ()
  in
  let rec close_pipe () =
    try ignore @@ U.close_process_in ic
    with
    | U.Unix_error (U.EINTR, _, _) -> close_pipe ()
    | U.Unix_error _ -> ()
  in
  Fun.protect ~finally:close_pipe @@
  fun () ->
  let res = f ic in
  match U.close_process_in ic with
  | U.WEXITED 0 -> ret res
  | U.WEXITED i ->
    E.error_system_msgf ~src "The command `%s' exited with the code %i" cmd i
  | U.WSIGNALED i ->
    E.error_system_msgf ~src "The command `%s' was interrupted by the signal %i" cmd i
  | U.WSTOPPED i ->
    E.error_system_msgf ~src "The command `%s' was stopped by the signal %i" cmd i
  | exception U.Unix_error (e, _, _) ->
    E.error_system_msg ~src @@ U.error_message e
