open Datatypes
open Utils
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
