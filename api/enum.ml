type 'a node =
| Stop
| Continue of 'a * 'a t
(* Type of enumerations. Either nothing or a partial answer together with the 
  call required to continue. *)

and 'a t = 'a node Call.t

let collapse (l : 'a t Call.t) =
  Call.bind l (fun x -> x)

let empty () = Call.return Stop

let rec of_list = function
| [] ->
  Call.return Stop
| x :: l ->
  Call.return (Continue (x, of_list l))

let rec iter f l =
  let iter_aux f = function
  | Stop -> Call.return ()
  | Continue (x, l) -> Call.bind (f x) (fun () -> iter f l)
  in
  Call.bind l (iter_aux f)

let rec fold f accu l =
  let fold_aux f accu = function
  | Stop -> Call.return accu
  | Continue (x, l) ->
    Call.map (fun ans -> f ans x) (fold f accu l)
  in
  Call.bind l (fold_aux f accu)

let rec map f l =
  let map_aux f = function
  | Stop -> Call.return Stop
  | Continue (x, l) -> Call.return (Continue (f x, map f l))
  in
  Call.bind l (map_aux f)

let rec append l1 l2 =
  let append_aux l1 l2 = match l1 with
  | Stop -> l2
  | Continue (x, l1) ->
    Call.return (Continue (x, append l1 l2))
  in
  Call.bind l1 (fun l1 -> append_aux l1 l2)

let rec filter f l =
  let filter_aux f = function
  | Stop -> Call.return Stop
  | Continue (x, l) ->
    Call.bind (f x) (fun b ->
      if b then Call.return (Continue (x, filter f l))
      else filter f l)
  in
  Call.bind l (filter_aux f)

let rec filter_map f l =
  let filter_map_aux f = function
  | Stop -> Call.return Stop
  | Continue (x, l) ->
    let next = function
    | None -> filter_map f l
    | Some x -> Call.return (Continue (x, filter_map f l))
    in
    Call.bind (f x) next
  in
  Call.bind l (filter_map_aux f)

let rec concat l =
  let concat_aux = function
  | Stop -> Call.return Stop
  | Continue (xs, l) -> append xs (concat l)
  in
  Call.bind l concat_aux

let rec combine l1 l2 =
  let head = Call.parallel l1 l2 in
  let f = function
  | Continue (x1, l1), Continue (x2, l2) ->
    Call.return (Continue ((x1, x2), combine l1 l2))
  | _ -> Call.return Stop
  in
  Call.bind head f
