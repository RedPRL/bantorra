module Syntax =
struct
  let ret = Result.ok
  let error = Result.error
  let (>>=) = Result.bind
  let (<$>) = Result.map
  let (let*) = Result.bind
  let[@inline] (and*) m n = let* m = m in let* n = n in ret (m, n)
  let[@inline] (let+) m f = Result.map f m
  let (and+) = (and*)
end

open Syntax

let ignore_error m = Result.value ~default:() m

let rec map f =
  function
  | [] -> ret []
  | x :: xs ->
    let+ y = f x
    and+ ys = map f xs in
    y :: ys

let rec iter f =
  function
  | [] -> ret ()
  | x :: xs ->
    let* () = f x in
    iter f xs

let rec iter_seq f s =
  match s () with
  | Seq.Nil -> ret ()
  | Seq.Cons (x, xs) ->
    let* () = f x in
    iter_seq f xs
