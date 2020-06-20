open File

type json_value = Ezjsonm.value
type json = Ezjsonm.t

let digest_of_value v = v |> Ezjsonm.value_to_string |> Digest.string |> Digest.to_hex

let of_gzip z = z |> Ezgzip.decompress |> Result.get_ok |> Ezjsonm.from_string
let to_gzip j = j |> Ezjsonm.to_string ~minify:true |> Ezgzip.compress

let writefile path j = writefile path @@ to_gzip j
let readfile path = of_gzip @@ readfile path
