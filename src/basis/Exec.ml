module U = UnixLabels
open ResultMonad.Syntax

let system ~prog ~args =
  let cmd = Filename.quote_command prog args in
  match U.system cmd with
  | U.WEXITED 0 -> ret ()
  | U.WEXITED i -> error @@ `Exit i
  | U.WSIGNALED i -> error @@ `Signaled i
  | U.WSTOPPED i -> error @@ `Stopped i
  | exception U.Unix_error (e, _, _) -> error @@ `SystemError (U.error_message e)

let with_system_in ~prog ~args f =
  let cmd = Filename.quote_command prog args in
  let* ic =
    try ret @@ U.open_process_in cmd
    with U.Unix_error (e, _, _) -> error @@ `SystemError (U.error_message e)
  in
  let close_pipe () =
    try ignore @@ UnixLabels.close_process_in ic
    with UnixLabels.Unix_error _ -> ()
  in
  Fun.protect ~finally:close_pipe @@
  fun () ->
  let res = f ic in
  match UnixLabels.close_process_in ic with
  | UnixLabels.WEXITED 0 -> ret res
  | U.WEXITED i -> error @@ `Exit i
  | U.WSIGNALED i -> error @@ `Signaled i
  | U.WSTOPPED i -> error @@ `Stopped i
  | exception U.Unix_error (e, _, _) -> error @@ `SystemError (U.error_message e)
