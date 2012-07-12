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

type void

type 'a t = 'a cont -> void

and 'a cont = {
  get : call -> Xml.elt t;
  mix : 'r. 'r t list -> 'r list t;
  knt : 'a -> void;
}

type 'a request = {
  mutable result : 'a result;
  process : 'a t;
}

(* Fooling the type system *)
let dummy : void = Obj.magic 0

let return x k = k.knt x

let map f (m : 'a t) (k : 'b cont) =
  let fk = { k with knt = fun x -> k.knt (f x) } in
  m fk

let bind (m : 'a t) (f : 'a -> 'b t) (k : 'b cont) =
  let fk = { k with knt = fun x -> (f x) k } in
  m fk

let http call k = k.get call k

let join (l : 'a t list) (k : 'a list cont) = k.mix l k

let parallel (m : 'a t) (n : 'b t) (k : ('a * 'b) cont) =
  let l = [Obj.magic m; Obj.magic n] in
  let f = function
  | [m; n] -> (Obj.magic m, Obj.magic n)
  | _ -> assert false
  in
  map f (join l) k

let cast call f = {
  base_call = call;
  treat_cookie = f;
}

let result c = c.result

let push_callback (p : pipeline) cb =
  let q = p#event_system in
  let group = q#new_group () in
  let f () = cb (); q#clear group in
  Unixqueue.epsilon q f

let instantiate f =
  { result = Unserved; process = f; }

(* let make c f = make_raw (K (fun get -> bind (get c) (fun x -> return (f x)))) *)

let rec get_header hd = function
| [] -> None
| (n, v) :: t ->
  if String.lowercase n = hd
    then Some (String.lowercase v)
    else get_header hd t

(* From an array [|Some x1; ...; Some xn|] to a list [x1; ...; xn] *)
let of_option_array a =
  let len = Array.length a in
  let rec aux n accu =
    if n < 0 then accu
    else
      match a.(n) with
      | None -> invalid_arg "of_option_array"
      | Some x -> aux (pred n) (x :: accu)
  in
  aux (pred len) []


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
  let set_result ans = call.result <- Successful ans; dummy in
  let finally f arg =
    try ignore (f arg) with err ->
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
  (* This is the function used to process HTTP calls *)
  let get { base_call = call; treat_cookie = cks } k =
    (* Retrieve the resulting HTTP call and ensure that no exception may escape *)
    let cb rq = finally (fun rq -> k.knt (parse_call cks rq)) rq in
    (* Copy the HTTP call in order to be purely functional *)
    let call = call#same_call () in
    let () = call#set_reconnect_mode Send_again in
    (* Push the call in the queue *)
    p#add_with_callback call cb;
    dummy
  in
  (*
    This is the function used to do parallel computation:
    It pushes a list of callbacks on the stack and ensures proper management
  *)
  let mix l k =
    let len = List.length l in
    let ans = Array.create len None in
    let answered = ref 0 in
    let push_nth_cb i call =
      let nk v =
        (* Should we put a mutex here? *)
        let () = ans.(i) <- Some v in
        let () = incr answered in
        if !answered = len then k.knt (of_option_array ans)
        else dummy
      in
      let cont = { k with knt = nk } in
      (* We need to ensure that we catch any exception that may be raised *)
      push_callback p (fun () -> finally call cont)
    in
    BatList.iteri push_nth_cb l;
    dummy
  in

  let k = { get = get; mix = mix; knt = set_result; } in
  let callback () = finally call.process k in
  push_callback p callback
