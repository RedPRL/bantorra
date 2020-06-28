let system ~prog ~args =
  let cmd = Filename.quote_command prog args in
  match UnixLabels.system cmd with
  | UnixLabels.WEXITED 0 -> ()
  | _ -> failwith @@ "non-zero exit code: " ^ cmd

let with_system_in ~prog ~args f =
  let cmd = Filename.quote_command prog args in
  let ic = UnixLabels.open_process_in cmd in
  try
    let res = f ic in
    match UnixLabels.close_process_in ic with
    | UnixLabels.WEXITED 0 -> res
    | _ -> failwith @@ "non-zero exit code: " ^ cmd
  with e ->
    ignore @@ UnixLabels.close_process_in ic;
    raise e
