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

let call f obj (q : query) cookies =
  let query = obj#site#query q in
  let call = f query in
  let hd = call#request_header `Base in
  let agent = match obj#username with
  | None -> "mlwiki"
  | Some name -> sprintf "mlwiki::%s" name
  in
  let mime = "application/x-www-form-urlencoded" in
  let () = Cookie.set_cookie hd cookies in
  let () = hd#update_field "User-Agent" agent in
  let () = hd#update_field "Content-Type" mime in
  let () = hd#update_field "Content-Length" "0" in
  let () = hd#update_field "Accept-Encoding" "gzip" in
  call

class virtual generic_session site =
  object (self)

    (* FIXME : use non redundant structure *)
    val mutable virtual cookies : Cookie.t list
    val mutable edit_token : token option = None
    val mutable valid = true

    method site : site = site

    method get_call q =
      Call.cast (call (new get) self q cookies) self#set_cookie

    method post_call q =
      Call.cast (call (fun q -> new post q []) self q cookies) self#set_cookie

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

  end

let rec login site lg : session =
  let query = site#query [
    "action", Some "login";
    "lgname", Some lg.login_name;
    "lgpassword", Some lg.login_password;
    "lgtoken", lg.login_token;
  ] in
(*  let query = match lg.login_token with
  | None -> query
  | Some tkn -> sprintf "%s&lgtoken=%s" query tkn
  in*)
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
      initializer site#set_session self
      val mutable cookies = cookies
      inherit generic_session site
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

let anonymous_login site =
  object (self)
    val mutable cookies = []
    inherit generic_session site
    method username = None
    method userid = 0L
    method private set_invalid () = ()
  end
