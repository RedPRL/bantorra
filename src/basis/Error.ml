let[@inline] error_msg ~tag ~src msg =
  Format.kasprintf tag "Reported from %s:\n  %s" src msg

let error_msgf ~tag ~src =
  Format.kasprintf (error_msg ~tag ~src)

let append_tag ~tag ~earlier =
  Format.kasprintf tag "%s\n%s" earlier

let append_error_msg ~tag ~earlier =
  error_msg ~tag:(append_tag ~tag ~earlier)

let append_error_msgf ~tag ~earlier =
  error_msgf ~tag:(append_tag ~tag ~earlier)

let pp_lines fmt msg =
  Format.fprintf fmt "@[<v>";
  Format.(pp_print_list ~pp_sep:pp_print_cut pp_print_string) fmt @@
  String.split_on_char '\n' msg;
  Format.fprintf fmt "@]"
