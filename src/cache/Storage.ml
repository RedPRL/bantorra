module J = Ezjsonm
module G = Ezgzip

open Util

type json_value = J.value
type json = J.t

type t = {root: string}

let init ~root =
  ensure_dir (root/"data");
  {root}

let replace {root} ~key ~value =
  let key = Digest.to_hex @@ Digest.string @@ J.to_string ~minify:true key
  and value = G.compress @@ J.to_string ~minify:true value in
  writefile (root/"data"/key) value;
  Digest.to_hex @@ Digest.string value

let find_opt {root} ~key ~digest =
  let key = Digest.to_hex @@ Digest.string @@ J.to_string ~minify:true key in
  match
    let value = readfile (root/"data"/key) in
    begin
      match digest with
      | Some d -> if Digest.string value <> d then raise Not_found
      | None -> ()
    end;
    Result.map J.from_string @@ G.decompress value
  with
  | Ok json -> Some json
  | Error _ -> None
  | exception _ -> None
