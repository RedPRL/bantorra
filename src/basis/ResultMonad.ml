module Syntax =
struct
  let (>>=) = Result.bind
  let (<$>) = Result.map
  let (let*) = Result.bind
  let[@inline] (let+) m f = Result.map f m
  let ret = Result.ok
  let[@inline] (and*) m n = let* m = m in let* n = n in ret (m, n)
  let (and+) = (and*)
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

let rec iter f =
  function
  | [] -> ret ()
  | x :: l ->
    let* () = f x in
    iter f l

let rec iter_seq f s =
  match s () with
  | Seq.Nil -> ret ()
  | Seq.Cons (x, s) ->
    let* () = f x in
    iter_seq f s
