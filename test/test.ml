open BantorraCache
let () = print_endline "Testing the database located at /tmp/bantorra/testing"
let db = Database.init ~root:"/tmp/bantorra/testing"
let () = print_endline "Adding an item..."
let digest = Database.replace_item db ~key:`Null ~value:(`A [])
let () = print_endline "Finding an item without checking its digest..."
let () =
  match Database.find_item_opt db ~key:`Null ~digest:None with
  | Some `A [] -> ()
  | _ -> assert false
let () = print_endline "Finding an item with the correct digest..."
let () =
  match Database.find_item_opt db ~key:`Null ~digest:(Some digest)  with
  | Some `A [] -> ()
  | _ -> assert false
let () = print_endline "Finding an item with a wrong digest..."
let () =
  match Database.find_item_opt db ~key:`Null ~digest:(Some "123") with
  | None -> ()
  | _ -> assert false
let () = print_endline "Saving the database meta information..."
let () = Database.save db
