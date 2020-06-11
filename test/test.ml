open Backend.Converter

let of_json = Lmdb.Conv.serialise json_conv
let to_json = Lmdb.Conv.deserialise json_conv

let () =
  Format.printf "Test 1: json -> zipped bigstring -> json@.";
  let x : json = `A [`Null; `O (List.init 10000 (fun i -> "test" ^ string_of_int i, `A [`String "something"])); `Bool true] in
  assert (x = to_json @@ of_json Bigstringaf.create x)
