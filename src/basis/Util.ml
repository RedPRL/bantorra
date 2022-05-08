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

  let of_unique_list l =
    of_unique_seq @@ List.to_seq l
end

let string_of_path = String.concat "."

let pp_path fmt path = Format.pp_print_string fmt @@ string_of_path path
