module J = Json_encoding

type t = { mounts : Router.param Trie.t }

module Json =
struct
  let format v = J.req ~title:"format version" ~description:"format version of the anchor file" "format" (J.constant v)
  (* let source_dir = J.dft ~title:"Source directory" ~description:"source directory (default: \"./\")" "source_dir" J.string "./" *)
  let mounts = J.dft ~title:"library mounts" ~description:"list of library mounts" "mounts" (J.assoc J.any_ezjson_value) []
  let anchor v = J.obj2 (format v) mounts
end

let read ~version ~premount path : t =
  let (), routes = Marshal.read (Json.anchor version) path in
  let mounts = List.fold_right (fun (path, route) -> Trie.add (UnitPath.of_string path) route) routes premount in
  { mounts }

let dispatch_path {mounts; _} path = Trie.find path mounts

let path_is_local anchor path =
  Option.is_none @@ dispatch_path anchor path
