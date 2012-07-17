type 'a t = {
  chunk : 'a list;
  continue : 'a t Call.t option;
}
(* Type of enumerations. A partial answer together with the 
  call required to continue. *)

let collapse (l : 'a t Call.t) : 'a t = {
  chunk = [];
  continue = Some l;
}

let empty () = {
  chunk = [];
  continue = None;
}

let rec of_list l = {
  chunk = l;
  continue = None;
}

let rec iter f l =
  let chunk_call =
    Call.map (fun _ -> List.iter f l.chunk) (Call.return ())
  in
  let continue_call = match l.continue with
  | None -> Call.return ()
  | Some call -> Call.bind call (iter f)
  in
  Call.bind chunk_call (fun _ ->
  Call.bind continue_call (fun _ -> Call.return ()))

let rec iter_s f l =
  let rec iter_aux = function
  | [] -> Call.return ()
  | x :: l -> Call.bind (f x) (fun () -> iter_aux l)
  in
  let call = match l.continue with
  | None -> Call.return ()
  | Some l -> Call.bind l (iter_s f)
  in
  Call.bind (iter_aux l.chunk) (fun () -> call)

let rec iter_p f l =
  let chunk_call = Call.join (BatList.map f l.chunk) in
  let continue_call = match l.continue with
  | None -> Call.return ()
  | Some call -> Call.bind call (iter_p f)
  in
  let par_call = Call.parallel chunk_call continue_call in
  Call.map (fun _ -> ()) par_call

let rec fold f accu l =
  let accu = List.fold_left f accu l.chunk in
  match l.continue with
  | None -> Call.return accu
  | Some call -> Call.bind call (fold f accu)

let rec map f l =
  let chunk = BatList.map f l.chunk in
  let continue = match l.continue with
  | None -> None
  | Some call -> Some (Call.map (map f) call)
  in
  { chunk; continue }

let rec map_s f l =
  let rec chunk_call = function
  | [] -> Call.return []
  | x :: l ->
    Call.bind (f x) (fun r ->
    Call.bind (chunk_call l) (fun l -> Call.return (r :: l)))
  in
  let continue_call = match l.continue with
  | None -> Call.return None
  | Some call -> Call.map (fun l -> Some (map_s f l)) call
  in
  Call.bind (chunk_call l.chunk) (fun chunk ->
  Call.bind continue_call (fun continue ->
  Call.return { chunk; continue }))

let map_s f l = collapse (map_s f l)

let rec map_p f l =
  let chunk_call = Call.join (BatList.map f l.chunk) in
  let continue_call = match l.continue with
  | None -> Call.return None
  | Some call -> Call.map (fun l -> Some (map_p f l)) call
  in
  let par_call = Call.parallel chunk_call continue_call in
  Call.map (fun (chunk, continue) -> {chunk; continue}) par_call

let map_p f l = collapse (map_p f l)

let rec append l1 l2 = match l1.continue with
| None ->
  let chunk = BatList.append l1.chunk l2.chunk in
  let continue = l2.continue in
  { chunk; continue }
| Some call ->
  let continue = Some (Call.map (fun l -> append l l2) call) in
  { chunk = l1.chunk; continue }

let rec filter f l =
  let chunk = BatList.filter f l.chunk in
  let continue = match l.continue with
  | None -> None
  | Some call -> Some (Call.map (filter f) call)
  in
  { chunk; continue }

let rec filter_s f l =
  let rec chunk_call = function
  | [] -> Call.return []
  | x :: l ->
    Call.bind (f x) (fun b ->
    Call.bind (chunk_call l) (fun l ->
      if b then Call.return (x :: l)
      else Call.return l
    ))
  in
  let continue_call = match l.continue with
  | None -> Call.return None
  | Some call -> Call.map (fun l -> Some (filter_s f l)) call
  in
  Call.bind (chunk_call l.chunk) (fun chunk ->
  Call.bind continue_call (fun continue ->
  Call.return { chunk; continue }))

let filter_s f l = collapse (filter_s f l)

let rec filter_map f l =
  let chunk = BatList.filter_map f l.chunk in
  let continue = match l.continue with
  | None -> None
  | Some call -> Some (Call.map (filter_map f) call)
  in
  { chunk; continue }

let rec find f l =
  let opt_ans = BatList.Exceptionless.find f l.chunk in
  match opt_ans with
  | None ->
    begin match l.continue with
    | None -> Call.return None
    | Some call -> Call.bind call (find f)
    end
  | _ -> Call.return opt_ans

let rec concat l =
  let next = match l.continue with
  | None -> empty ()
  | Some call -> collapse (Call.map concat call)
  in
  BatList.fold_right append l.chunk next

(* TODO : combine function *)
