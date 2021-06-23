open BantorraBasis
open ResultMonad.Syntax

include BantorraBasis.Errors

let tag msg = error @@ `UnitNotFound msg
let error_unit_not_found_msg ~src = Error.error_msg ~tag ~src
let error_unit_not_found_msgf ~src = Error.error_msgf ~tag ~src
let append_error_unit_not_found_msg ~src = Error.append_error_msg ~tag ~src
let append_error_unit_not_found_msgf ~src = Error.append_error_msgf ~tag ~src
let open_error_unit_not_found =
  function Ok _ as r -> r | Error (`UnitNotFound _) as r -> r

let tag msg = error @@ `InvalidLibrary msg
let error_invalid_library_msg ~src = Error.error_msg ~tag ~src
let error_invalid_library_msgf ~src = Error.error_msgf ~tag ~src
let append_error_invalid_library_msg ~src = Error.append_error_msg ~tag ~src
let append_error_invalid_library_msgf ~src = Error.append_error_msgf ~tag ~src
let open_error_invalid_library =
  function Ok _ as r -> r | Error (`InvalidLibrary _) as r -> r

let tag msg = error @@ `InvalidRouter msg
let error_invalid_router_msg ~src = Error.error_msg ~tag ~src
let error_invalid_router_msgf ~src = Error.error_msgf ~tag ~src
let append_error_invalid_router_msg ~src = Error.append_error_msg ~tag ~src
let append_error_invalid_router_msgf ~src = Error.append_error_msgf ~tag ~src
let open_error_invalid_router =
  function Ok _ as r -> r | Error (`InvalidRouter _) as r -> r
