module J = Json_encoding
open BantorraBasis
module E = Error

type t =
  { routes : Router.route Trie.t }

module Enc =
struct
  let version v = J.req ~title:"version" ~description:"format version" "version" (J.constant v)
  (* let source_dir = J.dft ~title:"Source directory" ~description:"source directory (default: \"./\")" "source_dir" J.string "./" *)
  let routes = J.dft ~title:"Routes" ~description:"routes" "routes" (J.assoc J.any_ezjson_value) []

  let anchor v = J.obj2 (version v) routes
end

let read ~version path : t =
  let (), routes = Marshal.read (Enc.anchor version) path in
  let routes = List.fold_right (fun (path, route) -> Trie.add (UnitPath.of_string path) route) routes Trie.empty in
  { routes }

let iter_routes f a = Trie.iter_values f a.routes

let dispatch_path {routes; _} path = Trie.find path routes

let path_is_local anchor path =
  Option.is_none @@ dispatch_path anchor path
