open Datatypes
open Utils
open Xml
open Options

let ignore r = Call.return ()

let purge (session : session) titles =
  let titles = List.map string_of_title titles in
  let call = session#post_call [
    "action", Some "purge";
    "titles", Some (String.concat "|" titles);
  ] in
  Call.bind (Call.http call) ignore

let emailuser (session : session) ?(subject = "") ?(text = "")
    ?(ccme = false) user =
  let token = session#edit_token in
  let query = [
    "action", Some "emailuser";
    "subject", Some subject;
    "text", Some text;
    "target", Some user;
    "token", Some token.token;
  ] @ (arg_bool "ccme" ccme) in
  let call = session#post_call query in
  Call.bind (Call.http call) ignore

(* Watchlist management *)

let watch (session : session) title =
  let query = [ "action", Some "watch" ] @ (arg_title "" title) in
  let call = session#post_call query in
  Call.bind (Call.http call) ignore

let unwatch (session : session) title =
  let query = [
    "action", Some "watch";
    "unwatch", None ]
    @ (arg_title "" title) in
  let call = session#post_call query in
  Call.bind (Call.http call) ignore

(* Random pages *)

let random (session : session) ?(ns = []) ?(rdr = false) () =
  let process xml =
    let xml = find_by_tag "query" xml.children in
    let data = try_children "random" xml in
    let page = match data with
    | Element elt :: _ -> elt
    | _ -> invalid_arg "Enum.random"
    in
    Call.return (Make.make_title "page" page)
  in
  let call = session#get_call ([
    "action", Some "query";
    "list", Some "random";
  ] @ (arg_namespaces "rn" ns) @ (arg_bool "rnredirect" rdr)) in
  Call.bind (Call.http call) process

