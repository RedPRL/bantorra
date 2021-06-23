let[@inline] error_msg ~tag ~src msg =
  Printf.ksprintf tag "Reported from %s:\n  %s" src msg

let error_msgf ~tag ~src =
  let buf = Buffer.create 16 in
  let k fmt =
    Format.pp_print_flush fmt ();
    error_msg ~tag ~src @@ Buffer.contents buf
  in
  Format.(kfprintf k @@ formatter_of_buffer buf)

let append_tag ~tag ~earlier =
  Printf.ksprintf tag "%s\n%s" earlier

let append_error_msg ~tag ~earlier =
  error_msg ~tag:(append_tag ~tag ~earlier)

let append_error_msgf ~tag ~earlier =
  error_msgf ~tag:(append_tag ~tag ~earlier)

let pp_lines fmt msg =
  Format.(pp_print_list ~pp_sep:pp_print_newline pp_print_string) fmt @@
  String.split_on_char '\n' msg
