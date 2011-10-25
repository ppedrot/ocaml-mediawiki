open Datatypes
open Utils
open Call

exception Call_error of Call.error

let pipeline = new Http_client.pipeline

(* Configure TLS *)
let () =
  let () = Ssl.init () in 
  let ctx = Ssl.create_context Ssl.TLSv1 Ssl.Client_context in
  let tct = Https_client.https_transport_channel_type ctx in
  pipeline#configure_transport Http_client.https_cb_id tct

let force call = match result call with
| Unserved -> assert false
| Successful ans -> ans
| Failed err -> raise (Call_error err)

let process call =
  let call = Call.instantiate call in
  let () = Call.enqueue call pipeline in
  let () = pipeline#run () in
  force call
