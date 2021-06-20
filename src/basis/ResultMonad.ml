module Syntax =
struct
  let (>>=) = Result.bind
  let (let*) = Result.bind
  let[@inline] (let+) m f = Result.map f m
  let ret = Result.ok
  let error = Result.error
end

open Syntax

let rec map f =
  function
  | [] -> ret []
  | x :: l ->
    let* x = f x in
    let* l = map f l in
    ret @@ x :: l
