open Datatypes
open Utils

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

class existing_page (p : Datatypes.page) =
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

let pages_of_title session (s : string Set.t) : (string, page) Map.t =
  let call = Prop.of_titles session (Set.fold (fun x accu -> x :: accu) s []) in
  let ans = process call in
  let map = function
  | `EXISTING page -> assert false
  | `INVALID -> assert false
  | `MISSING title -> assert false
  in
  assert false
(*   Utils.MapString.map map ans *)
