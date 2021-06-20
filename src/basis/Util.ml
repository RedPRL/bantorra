open ResultMonad.Syntax

module Hashtbl =
struct
  let of_unique_seq (type key) seq =
    let exception DuplicateKeys of key in
    let tbl = Hashtbl.create 0 in
    try
      Seq.iter (fun (k, v) ->
          if Hashtbl.mem tbl k then
            raise @@ DuplicateKeys k
          else begin
            Hashtbl.replace tbl k v
          end) seq;
      ret tbl
    with
    | DuplicateKeys k -> error @@ `DuplicateKeys k
end
