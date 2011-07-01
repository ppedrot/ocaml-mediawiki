open Xml
open Datatypes
open Options
open Utils

let get_timestamp xml =
  let xml = find_by_tag "query" xml.children in
  let xml = find_by_tag "pages" xml.children in
  match xml.children with
  | Element elt :: _ ->
    let revs = find_by_tag "revisions" elt.children in
    let rev = find_by_tag "rev" revs.children in
    List.assoc "timestamp" rev.attribs
  | _ -> assert false

let get_edit_result xml =
  let data = find_by_tag "edit" xml.children in
  let result = List.assoc "result" data.attribs in
  match result with
  | "Success" ->
    if List.mem_assoc "new" data.attribs then `NEW
    else if List.mem_assoc "nochange" data.attribs then `NO_CHANGE
    else `UPDATE
  | "Failure" -> raise (Call.API "Failure")
  | _ -> assert false

let write_title (session : session) text ?summary ?(minor = `DEFAULT)
  ?(watch = `DEFAULT) ?(bot = false) ?(create = `DEFAULT) title =
  let token = session#edit_token in
  let digest = Digest.to_hex (Digest.string text) in
  let write_call = session#post_call ([
    "action", Some "edit";
    "title", Some (string_of_title title);
    "text", Some text;
    "summary", summary;
    "token", Some token.token;
    "md5", Some digest;
  ] @ (arg_minor_flag minor) @ (arg_watch_flag watch) @ (arg_bool "bot" bot)
    @ (arg_create_flag create))
  in
  Call.bind (Call.http write_call) (fun xml ->
  Call.return (get_edit_result xml))

let write_page (session : session) text ?summary ?(minor = `DEFAULT) 
  ?(watch = `DEFAULT) ?(bot = false) ?(create = `DEFAULT) page =
  let token = session#edit_token in
  let digest = Digest.to_hex (Digest.string text) in
(*  let ts_call = session#get_call [
    "action", Some "query";
    "prop", Some "revisions";
    "rvprop", Some "timestamp";
    "revids", Some (string_of_id page.page_lastrevid);
  ] in *)
  let ts = print_timestamp page.page_touched in
  let write_call = session#post_call ([
    "action", Some "edit";
    "title", Some (string_of_title page.page_title);
    "basetimestamp", Some ts;
    "text", Some text;
    "summary", summary;
    "token", Some token.token;
    "md5", Some digest;
  ] @ (arg_minor_flag minor) @ (arg_watch_flag watch) @ (arg_bool "bot" bot)
    @ (arg_create_flag create))
  in
  Call.bind (Call.http write_call) (fun xml ->
  Call.return (get_edit_result xml))
