open Http_client
open Printf
open Xml
open Site
open Utils
open Datatypes

let pipeline = new pipeline

type login = {
  login_name : string;
  login_password : string;
  login_token : string option;
  login_cookies : Cookie.t list;
}

let get_login name pass = {
  login_name = name;
  login_password = pass;
  login_token = None;
  login_cookies = [];
}

(* Generic call: embeds low-level stuff *)

let encode s = Netencoding.Url.encode ~plus:false s

let urlencode q =
  let map = function
  | (v, None) -> sprintf "&%s" (encode v)
  | (v, Some arg) -> sprintf "&%s=%s" (encode v) (encode arg)
  in
  String.concat "" (List.map map q) 

let call site username (q : query) cookies =
  let query = "format=xml" ^ urlencode q in
  let call = new post_raw site.site_api query in
  let hd = call#request_header `Base in
  let agent = match username with
  | None -> user_agent
  | Some name -> sprintf "%s::%s" user_agent name
  in
  let mime = "application/x-www-form-urlencoded" in
  let () = Cookie.set_cookie hd cookies in
  let () = hd#update_field "User-Agent" agent in
  let () = hd#update_field "Content-Type" mime in
  let () = hd#update_field "Content-Length" "0" in
  let () = hd#update_field "Accept-Encoding" "gzip" in
  call

class virtual generic_session site cookies =
  object (self)

    (* FIXME : use non redundant structure *)
    val mutable cookies = cookies
    val mutable edit_token : token option = None
    val mutable valid = true

    method site : site = site

    method virtual username : string option

    method get_call = self#post_call
(*       Call.cast (call (new get) self q cookies) self#set_cookie *)

    method post_call q =
      Call.cast (call self#site self#username q cookies) self#set_cookie

    method is_valid = valid

    method edit_token = match edit_token with
    | None ->
      let () = self#initialize_edit_token () in
      self#edit_token
    | Some tkn -> tkn

    method private set_cookie ck = cookies <- cookies @ [ck]

    method private initialize_edit_token () =
      let process_xml xml =
        let xml = find_by_tag "query" xml.children in
        let xml = find_by_tag "pages" xml.children in
        match xml.children with
        | Element { attribs = attribs } :: _ ->
          let token = List.assoc "edittoken" attribs in
          let ts = List.assoc "starttimestamp" attribs in
          let ts = Utils.parse_timestamp ts in
          { token = token; token_type = `EDIT; token_ts = ts; }
        | _ -> assert false
      in
      let dummy = "X" in
      let call = self#get_call [
        "action", Some "query";
        "prop", Some "info";
        "intoken", Some "edit";
        "titles", Some dummy;
      ] in
      let call = Call.bind (Call.http call)
        (fun xml -> Call.return (process_xml xml))
      in
      let request = Call.instantiate call in
      let () = Call.enqueue request pipeline in
      let () = pipeline#run () in
      match Call.result request with
      | Call.Successful tkn -> edit_token <- Some tkn
      | _ -> assert false (* FIXME *)

    method logout () =
      let call = self#get_call ["action", Some "logout"] in
      let call = Call.http call in
      let request = Call.instantiate call in
      let () = Call.enqueue request pipeline in
      let () = pipeline#run () in
      self#set_invalid ()

    method private virtual set_invalid : unit -> unit

    method save =
    (* Save the cookies as a list of name/value pairs *)
      let fold accu ck =
        let open Nethttp in
        let name = ck.cookie_name in
        let value = ck.cookie_value in
        (sprintf "%s\n%s\n" name value) ^ accu
      in
      List.fold_left fold "" cookies

  end

let rec login site lg : session =
  let query = urlencode [
    "action", Some "login";
    "lgname", Some lg.login_name;
    "lgpassword", Some lg.login_password;
    "lgtoken", lg.login_token;
  ] in
  let query = site.site_api ^ query in
  let call = new post query [] in
  let () = Cookie.set_cookie (call#request_header `Base) lg.login_cookies in
  let () = pipeline#add call in
  let () = pipeline#run () in
  let xml = Xml.parse_string call#response_body#value in
  let data = find_by_tag "login" xml.children in
  let result = List.assoc "result" data.attribs in
  begin match result with
  | "Success" ->
    let id = id_of_string (List.assoc "lguserid" data.attribs) in
    let name = List.assoc "lgusername" data.attribs in
    let cookies = Cookie.get_set_cookie call#response_header in
    object (self)
      inherit generic_session site cookies
      method username = Some name
      method userid = id
      method private set_invalid () = valid <- false
    end
  | "NeedToken" ->
    let token = List.assoc "token" data.attribs in
    let cookies = Cookie.get_set_cookie call#response_header in
    let nlg = { lg with login_token = Some token; login_cookies = cookies; } in
    login site nlg
(*  | "NoName"
  | "Illegal"
  | "NotExists"
  | "EmptyPass"
  | "WrongPass"
  | "WrongPluginPass"
  | "CreateBlocked"
  | "Throttled"
  | "Blocked"*)
  | err -> failwith ("Error: " ^ err)
  end

let login site name pwd =
  login site (get_login name pwd)

let anonymous_login site =
  object (self)
    inherit generic_session site []
    method username = None
    method userid = 0L
    method private set_invalid () = ()
  end

let relogin site s =
  let rec split s off accu =
    let i = try String.index_from s off '\n' with Not_found -> -1 in
    if i < 0 then (String.sub s off (String.length s - off)) :: accu
    else
      let sub = String.sub s off (i - off) in
      split s (succ i) (sub :: accu)
  in
  let cookies = List.rev (split s 0 []) in
  let rec make_cookies accu = function
  | name :: value :: cks ->
    let ck = Nethttp.Cookie.make name value in
    let ck = Nethttp.Cookie.to_netscape_cookie ck in
    make_cookies (ck :: accu) cks
  | _ -> accu
  in
  let cookies = make_cookies [] cookies in
  let ans =
    object (self)
      val mutable username = None
      val mutable userid = -1L
      inherit generic_session site cookies

      method private check_login () =
        (* Check that we are actually logged by retrieving the username *)
        let process xml =
          let xml = find_by_tag "query" xml.Xml.children in
          let xml = find_by_tag "userinfo" xml.Xml.children in
          let attrs = xml.Xml.attribs in
          let name = List.assoc "name" attrs in
          let id = id_of_string (List.assoc "id" attrs) in
          let is_anon = List.mem_assoc "anon" attrs in
          Call.return (name, id, is_anon)
        in
        let call = self#get_call [
          "action", Some "query";
          "meta", Some "userinfo";
        ] in
        let call = Call.bind (Call.http call) process in
        let request = Call.instantiate call in
        let () = Call.enqueue request pipeline in
        let () = pipeline#run () in
        match Call.result request with
        | Call.Successful (name, id, is_anon) ->
          let () = username <- Some name in
          let () = userid <- id in
          if is_anon then failwith "Could not connect."
        | _ -> assert false (* FIXME *)    

      method initialize () = self#check_login ()

      method private set_invalid () = valid <- false

      method username = username

      method userid = userid

    end
  in
  (* Ensure that we are connected *)
  let () = ans#initialize() in
  (ans :> session)
