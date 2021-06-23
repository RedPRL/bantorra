open ResultMonad.Syntax
open Error

let tag msg = error @@ `SystemError msg
let error_system_msg ~src = error_msg ~tag ~src
let error_system_msgf ~src = error_msgf ~tag ~src
let append_error_system_msg ~src = append_error_msg ~tag ~src
let append_error_system_msgf ~src = append_error_msgf ~tag ~src

let tag msg = error @@ `AnchorNotFound msg
let error_anchor_not_found_msg ~src = error_msg ~tag ~src
let error_anchor_not_found_msgf ~src = error_msgf ~tag ~src
let append_error_anchor_not_found_msg ~src = append_error_msg ~tag ~src
let append_error_anchor_not_found_msgf ~src = append_error_msgf ~tag ~src

let tag msg = error @@ `FormatError msg
let error_format_msg ~src = error_msg ~tag ~src
let error_format_msgf ~src = error_msgf ~tag ~src
let append_error_format_msg ~src = append_error_msg ~tag ~src
let append_error_format_msgf ~src = append_error_msgf ~tag ~src
