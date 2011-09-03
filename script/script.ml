open Datatypes
open Utils
open Call

exception Undefined
exception Call_error of Call.error

let pipeline = new Http_client.pipeline

let force call = match result call with
| Unserved -> assert false
| Successful ans -> ans
| Failed err -> raise (Call_error err)

let process call =
  let call = Call.instantiate call in
  let () = Call.enqueue call pipeline in
  let () = pipeline#run () in
  force call
