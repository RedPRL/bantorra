open BantorraBasis
module E = Error

type param = Json_repr.ezjsonm
type t = param -> File.path
type pipe = param -> param

module Eff = Algaeff.Reader.Make(struct type env = FilePath.t end)
let get_lib_root = Eff.read
let run ~lib_root = Eff.run ~env:lib_root
