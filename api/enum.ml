type 'a node =
| Stop
| Continue of 'a * 'a t
(* Type of enumerations. Either nothing or a partial answer together with the 
  call required to continue. *)

and 'a t = 'a node Call.t

let rec iter f l = Call.bind l (iter_aux f)

and iter_aux f = function
| Stop -> Call.return ()
| Continue (x, l) -> let () = f x in iter f l

let rec fold f accu l = Call.bind l (fold_aux f accu)

and fold_aux f accu = function
| Stop -> Call.return accu
| Continue (x, l) ->
  Call.map (fun ans -> f ans x) (fold f accu l)

let rec map f l = Call.bind l (map_aux f)

and map_aux f = function
| Stop -> Call.return Stop
| Continue (x, l) -> Call.return (Continue (f x, map f l))

 
