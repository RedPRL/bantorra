module J = Jsonm
module Z = Zlib
module S = Bigstringaf

type bigstring = S.t

(** This is intended to be fully compatible with ezjsonm. *)
type json_value =
  [ `Null
  | `Bool of bool
  | `Float of float
  | `String of string
  | `A of json_value list
  | `O of (string * json_value) list
  ]

(** This is intended to be fully compatible with ezjsonm. *)
type json =
  [ `A of json_value list
  | `O of (string * json_value) list
  ]

exception JsonDecoderError of J.error
exception Impossible

let prepand_zlib_header = false (* Change this to [true] for debugging *)

type 'a bwd = Nil | Snoc of 'a bwd * 'a
let zip (alloc : int -> bigstring) (filler : bytes -> int) : bigstring =
  let output_size = ref 0 in
  let output_parcel_stack = ref Nil in
  let collector output_buf size =
    let output_parcel = Bytes.sub output_buf 0 size in
    output_parcel_stack := Snoc (!output_parcel_stack, output_parcel);
    output_size := !output_size + size;
  in
  Z.compress ~header:prepand_zlib_header filler collector;
  let bs = alloc !output_size in
  let rec pour ending =
    function
    | Nil -> ()
    | Snoc (stack, parcel) ->
      let len = Bytes.length parcel in
      let dst_off = ending - len in
      S.blit_from_bytes parcel ~src_off:0 bs ~dst_off ~len;
      (pour[@tailcall]) dst_off stack
  in
  pour !output_size !output_parcel_stack;
  bs

type 'a stream = Nil | Cons of 'a * (unit -> 'a stream)
let nil = Nil
let cons x k = Cons (x, k)
let json_lexeme_stream_of_json_value : json -> _ stream =
  let rec go_value =
    function
    | `Null -> cons `Null
    | `Bool b -> cons (`Bool b)
    | `Float f -> cons (`Float f)
    | `String s -> cons (`String s)
    | `A vs -> (go_arr[@tailcall]) vs
    | `O ms -> (go_obj[@tailcall]) ms
  and go_arr vs kont =
    cons `As @@ fun () -> (go_arr_vs[@tailcall]) vs @@ fun () -> cons `Ae kont
  and go_arr_vs vs kont =
    match vs with
    | [] -> kont ()
    | v :: vs -> (go_value[@tailcall]) v @@ fun () -> go_arr_vs vs kont
  and go_obj ms kont =
    cons `Os @@ fun () -> (go_obj_ms[@tailcall]) ms @@ fun () -> cons `Oe kont
  and go_obj_ms ms kont =
    match ms with
    | [] -> kont ()
    | (k, v) :: ms -> cons (`Name k) @@ fun () -> (go_value[@tailcall]) v @@ fun () -> go_obj_ms ms kont
  in
  function
  | `A vs -> go_arr vs @@ fun () -> nil
  | `O ms -> go_obj ms @@ fun () -> nil

let filler_from_json_lexeme_stream (s : _ stream) : bytes -> int =
  let cur_stream = ref @@ Some s in
  let encoder = J.encoder ~minify:true `Manual in
  fun buf ->
    let buf_size = Bytes.length buf in
    let rec go =
      function
      | `Ok ->
        begin
          match !cur_stream with
          | None ->
            (* the end *) 0
          | Some Nil ->
            cur_stream := None;
            (go[@tailcall]) (J.encode encoder `End);
          | Some Cons (t, s) ->
            cur_stream := Some (s ());
            (go[@tailcall]) (J.encode encoder @@ `Lexeme t)
        end
      | `Partial ->
        let output_len = buf_size - J.Manual.dst_rem encoder in
        if output_len = 0 then
          (* The above line always returns [`Partial] and thus ignored.

             The documentation seems to indicate [len - J.Manual.dst_rem encoder]
             could be zero when encoding [`End], which would make [Z.compress] think
             the stream has ended. Let's do [`Await] again.

             See https://github.com/dbuenzli/jsonm/pull/14.
          *)
          (go[@tailcall]) (J.encode encoder `Await)
        else
          output_len
    in
    J.Manual.dst encoder buf 0 buf_size;
    go @@ J.encode encoder `Await

let zipped_bigstring_of_json (alloc : int -> bigstring) (json : [< json]) : bigstring =
  json
  |> json_lexeme_stream_of_json_value
  |> filler_from_json_lexeme_stream
  |> zip alloc

let filler_from_zipped_bigstring (s : bigstring) : bytes -> int =
  let src_off = ref 0 in
  let string_len = S.length s in
  fun buf ->
    let len = min (string_len - !src_off) @@ Bytes.length buf in
    S.blit_to_bytes s ~src_off:!src_off buf ~dst_off:0 ~len;
    src_off := !src_off + len;
    len

type ('a, 'b) cont = Uninitialized | Done of 'a | Cont of ('b -> unit)
let unzip (filler : bytes -> int) : json =
  let kont = ref Uninitialized in
  let decoder = J.decoder `Manual in
  let read k : unit =
    match J.decode decoder with
    | `Lexeme l -> k l
    | `Error e -> raise @@ JsonDecoderError e
    | `End -> assert false
    | `Await -> kont := Cont k
  in
  let rec dispatch_value l k =
    match l with
    | `Os -> (read_obj_ms[@tailcall]) (fun vs -> k @@ `O vs)
    | `As -> (read_arr_vs[@tailcall]) (fun vs -> k @@ `A vs)
    | `Bool _ | `Float _ | `Null | `String _ as v -> k v
    | `Ae | `Oe | `Name _ -> raise Impossible
  and read_arr_vs k =
    (read[@tailcall]) begin function
      | `Ae -> k []
      | l ->
        (dispatch_value[@tailcall]) l @@ fun v ->
        (read_arr_vs[@tailcall]) begin fun vs ->
          k @@ v :: vs
        end
    end
  and read_obj_ms k =
    (read[@tailcall]) begin function
      | `Oe -> k []
      | `Name e ->
        (read[@tailcall]) begin fun l ->
          (dispatch_value[@tailcall]) l @@ fun v ->
          (read_obj_ms[@tailcall]) begin fun ms ->
            k @@ (e, v) :: ms
          end
        end
      | `Ae | `As | `Bool _ | `Float _ | `Null | `Os | `String _ -> raise Impossible
    end
  in
  let dispatch_json l k =
    match l with
    | `Os -> read_obj_ms @@ fun vs -> k @@ `O vs
    | `As -> read_arr_vs @@ fun vs -> k @@ `A vs
    | `Ae | `Bool _ | `Float _ | `Name _ | `Oe | `Null | `String _ -> raise Impossible
  in
  kont :=
    Cont begin
      fun l ->
        (dispatch_json[@tailcall]) l @@ fun v ->
        kont := Done v
    end;
  let resume buf buf_size =
    J.Manual.src decoder buf 0 buf_size;
    match !kont with
    | Cont k -> read k
    | Done _ -> () (* XXX extra input is ignored *)
    | Uninitialized -> raise Impossible
  in
  Z.uncompress ~header:prepand_zlib_header filler resume;
  resume Bytes.empty 0;
  match !kont with
  | Done v -> v
  | Cont _ -> raise Impossible
  | Uninitialized -> raise Impossible

let json_of_zipped_bigstring bigstring : json =
  bigstring |> filler_from_zipped_bigstring |> unzip

let json_conv =
  Lmdb.Conv.make
    ~serialise:zipped_bigstring_of_json
    ~deserialise:json_of_zipped_bigstring
    ()
