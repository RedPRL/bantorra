let has_duplication l =
  let tbl = Hashtbl.create 0 in
  let check e = Hashtbl.mem tbl e || (Hashtbl.replace tbl e (); false) in
  List.exists check l
