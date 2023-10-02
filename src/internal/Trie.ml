module StringMap = Map.Make(String)

type 'a node =
  { root : 'a option
  ; children : 'a node StringMap.t
  }
type 'a t = 'a node option

let empty : 'a t = None

let root_node d : _ node =
  { root = Some d; children = StringMap.empty }

let rec singleton_node p d =
  match p with
  | [] -> root_node d
  | seg::p ->
    { root = None; children = StringMap.singleton seg (singleton_node p d) }

let singleton_ p d = Some (singleton_node p d)

let singleton p d = singleton_ (UnitPath.to_list p) d

let add p d =
  let exception DuplicateUnitPath in
  let rec go_node p d n =
    match p with
    | [] -> begin match n.root with None -> {n with root = Some d} | _ -> raise DuplicateUnitPath end
    | seg::p -> {n with children = StringMap.update seg (go p d) n.children}
  and go p d =
    function
    | None -> singleton_ p d
    | Some n -> Some (go_node p d n)
  in
  try go (UnitPath.to_list p) d
  with DuplicateUnitPath -> Logger.fatalf `JSONFormat "Multiple libraries mounted at `%a'" UnitPath.pp p

let rec find_node p n =
  match
    match p with
    | [] -> None
    | seg::p -> find_ p (StringMap.find_opt seg n.children)
  with
  | None -> Option.map (fun d -> d, UnitPath.unsafe_of_list p) n.root
  | Some ans -> Some ans
and find_ p =
  function
  | None -> None
  | Some n -> find_node p n

let find p t = find_ (UnitPath.to_list p) t

let rec iter_values_node f {root; children} =
  Option.iter f root;
  StringMap.iter (fun _ -> iter_values_node f) children

let iter_values f m = Option.iter (iter_values_node f) m
