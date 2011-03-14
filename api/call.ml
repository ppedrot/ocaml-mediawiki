open Http_client
open Printf

type error =
| Network_Error of string
| API_Error of string
| Other_Error of exn

type 'a result =
| Unserved
| Failed of error
| Successful of 'a

exception API of string

type call = {
  base_call : http_call;
  treat_cookie : Cookie.t -> unit;
}

type 'a t =
| K of ((call -> Xml.elt t) -> ('a -> unit) -> unit)

type 'a request = {
  mutable result : 'a result;
  process : 'a t;
}

let return x = K (fun get k -> k x)

let unroll = function K f -> f

let bind (m : 'a t) (f : 'a -> 'b t) : 'b t =
match m with
| K fk ->
  let gk get k = fk get (fun x -> unroll (f x) get k) in
  K gk

let http call = K (fun get k -> unroll (get call) get k)

let cast call f = {
  base_call = call;
  treat_cookie = f;
}

let result c = c.result

let push_callback (p : pipeline) cb =
  let q = p#event_system in
  let group = q#new_group () in
  let f () = cb (); q#clear group in
  q#once group 0. f

let instantiate f =
  { result = Unserved; process = f; }

(* let make c f = make_raw (K (fun get -> bind (get c) (fun x -> return (f x)))) *)

let rec get_header hd = function
| [] -> None
| (n, v) :: t ->
  if String.lowercase n = hd
    then Some (String.lowercase v)
    else get_header hd t

(* TODO : analyze exn *)
let http_info exn = Printexc.to_string exn

let process_error xml =
  let rec find_err = function
  | [] -> ()
  | Xml.Element ({Xml.tag = "error"; Xml.attribs = attr}) :: _ ->
    let code =
      try List.assoc "code" attr
      with Not_found -> "nocode"
    in
    let info =
      try List.assoc "info" attr
      with Not_found -> "noinfo"
    in
    let err = sprintf "API error '%s': %s" code info in
    raise (API err)
  | _ :: t -> find_err t
  in
  find_err xml.Xml.children

let enqueue (call : 'a request) (p : pipeline) =
  let fail err = call.result <- Failed err; raise Exit in
  let set_result ans = call.result <- Successful ans in
  let finally f arg =
    try f arg with err ->
      let info = match err with
      | API err -> API_Error err
      | _ -> Other_Error err
      in
      match call.result with
      | Failed _ -> ()
      | _ -> call.result <- Failed info
  in
  let parse_xml (cks : Cookie.t -> unit) (rq : http_call) =
    let headers = rq#response_header in
    let body = rq#response_body in
    let encoding = get_header "content-encoding" headers#fields in
    let cookies = Cookie.get_set_cookie headers in
    let () = List.iter cks cookies in
    let chan = match encoding with
    | None -> body#open_value_rd ()
    | Some "gzip" ->
      let chan = body#open_value_rd () in
      Netgzip.input_inflate chan
    | Some enc ->
      let err = "Unsupported encoding: " ^ enc in
      fail (Network_Error err)
    in
    let xml =
      try Xml.parse_in_obj_channel chan
      with Expat.Expat_error err ->
        let info = "Malformed XML: " ^ (Expat.xml_error_to_string err) in
        fail (Network_Error info)
    in
    let () = chan#close_in () in
    (* TODO: check for error in header *)
    let () = process_error xml in
    xml
  in
  let parse_call cks rq = match rq#status with
  | `Unserved -> assert false
  | `Successful | `Redirection -> parse_xml cks rq
  | `Client_error | `Server_error ->
    let err = sprintf "HTTP Error: %i %s"
      rq#response_status_code rq#response_status_text
    in
    fail (Network_Error err)
  | `Http_protocol_error err ->
    let err = "Network Error: " ^ (http_info err) in
    fail (Network_Error err)
  in
  let get { base_call = call; treat_cookie = cks } =
    let cb k = finally (fun rq -> k (parse_call cks rq)) in
    (* Copy the HTTP call in order to be able to reuse it *)
    let call = call#same_call () in
    K (fun get k -> p#add_with_callback call (cb k))
  in
  let callback () = finally (match call.process with K f -> f get) set_result in
  push_callback p callback
