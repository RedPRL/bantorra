module Hashtbl =
struct
  let of_unique_seq s =
    let rec go tbl =
      function
      | Seq.Nil -> tbl
      | Seq.Cons ((k, v), next) ->
        if Hashtbl.mem tbl k then invalid_arg "of_unique_seq: duplicate keys";
        Hashtbl.replace tbl k v;
        (go[@tailcall]) tbl @@ next ()
    in
    go (Hashtbl.create 0) @@ s ()
end
