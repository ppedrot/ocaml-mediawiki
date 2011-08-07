open Datatypes

exception Undefined
exception Call_error of Call.error

let pipeline = new Http_client.pipeline

let force call = match Call.result call with
| Call.Unserved -> assert false
| Call.Successful assoc -> assoc
| Call.Failed err -> raise (Call_error err)

let process call =
  let call = Call.instantiate call in
  let () = Call.enqueue call pipeline in
  let () = pipeline#run () in
  force call

class type ['a] set =
  object
    method mem : 'a -> bool
    method iter : ('a -> unit) -> unit
    method fold : 'b. ('a -> 'b -> 'b) -> 'b -> 'b
    method elements : 'a list
  end

class type ['a, 'b] map =
  object ('self)
    method find : 'a -> 'b
    method iter : ('a -> 'b -> unit) -> unit
    method fold : 'c. ('a -> 'b -> 'c -> 'c) -> 'c -> 'c
  end

let set_of_list (l : 'a list) : 'a set =
  object
    method mem x = List.mem x l
    method iter f = List.iter f l
    method fold : 'b. ('a -> 'b -> 'b) -> 'b -> 'b =
      fun f accu -> List.fold_left (fun accu x -> f x accu) accu l
    method elements = l
  end

class type page =
  object
    method title : title
    method id : id
    method touched : timestamp
    method lastrevid : id
    method length : int
    method is_missing : bool
    method is_redirect : bool
    method is_new : bool
  end

let make_map (type elt) cmp =
  let module Ord = struct type t = elt let compare = cmp end in
  let module M = Map.Make(Ord) in
  (module M : Map.S with type key = elt)

class ['a] mapString m =
  object (self)
    method find x = Utils.MapString.find x m
    method iter f = Utils.MapString.iter f m
    method fold : 'c. (string -> 'a -> 'c -> 'c) -> 'c -> 'c =
      fun f -> Utils.MapString.fold f m
  end

class existing_page (p : Datatypes.page) : page =
  object
    method title = p.page_title
    method id = p.page_id
    method is_missing = false
    method is_new = p.page_new
    method is_redirect = p.page_redirect
    method length = p.page_length
    method lastrevid = p.page_lastrevid
    method touched = p.page_touched
  end

let pages_of_title session (s : string set) : page mapString =
  let call = Prop.of_titles session s#elements in
  let ans = process call in
  let map = function
  | `EXISTING page -> assert false
  | `INVALID -> assert false
  | `MISSING title -> assert false
  in
  assert false
(*   Utils.MapString.map map ans *)
