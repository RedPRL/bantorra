open Cache.Storage
let () = print_endline "Testing the database located at /tmp/bantorra/testing"
let db = Database.init ~root:"/tmp/bantorra/testing"
let digest = Database.replace_item db ~key:(`Null) ~value:(`A [])
let () =
  match Database.find_item_opt db ~key:(`Null) ~digest:None with
  | Some `A [] -> ()
  | _ -> assert false
let () =
  match Database.find_item_opt db ~key:(`Null) ~digest:(Some "123") with
  | None -> ()
  | _ -> assert false
let () = Database.save db
