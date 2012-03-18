open Xml
open WTypes
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

let get_move_result xml =
  let data = find_by_tag "move" xml.children in
  let attrs = data.attribs in
  let status =
    if List.mem_assoc "redirectcreated" attrs then `REDIRECTED
    else `NO_REDIRECT
  in
  let talk =
    try
      let pf = List.assoc "talkfrom" attrs in
      let pt = List.assoc "talkto" attrs in
      Some (pf, pt)
    with _ -> None
  in
  let map = function
  | Element { attribs = attrs } ->
    let pf = List.assoc "from" attrs in
    let pt = List.assoc "to" attrs in
    (pf, pt)
  | _ -> assert false
  in
  let subpage = try_children "subpages" data in
  let subtalk = try_children "subpages-talk" data in
  {
    moved_status = status;
    moved_page = (List.assoc "from" attrs, List.assoc "to" attrs);
    moved_talk = talk;
    moved_subpage = List.map map subpage;
    moved_subtalk = List.map map subtalk;
  }

let get_delete_result xml =
  let _ = find_by_tag "delete" xml.children in ()

let get_upload_result xml =
  let data = find_by_tag "upload" xml.children in
  let attrs = data.attribs in
  let status = match List.assoc "result" attrs with
  | "Success" -> `SUCCESS
  | "Warning" -> `WARNING
  | _ -> raise (Call.API "Upload Failure")
  in
  let filekey = try Some (List.assoc "filekey" attrs) with Not_found -> None in
  {
    upload_status = status;
    upload_filekey = filekey;
  }

let write_title (session : session) ?summary ?(minor = `DEFAULT)
  ?(watch = `DEFAULT) ?(bot = false) ?(create = `DEFAULT) title text =
  let token = session#edit_token in
  let digest = Digest.to_hex (Digest.string text) in
  let write_call = session#post_call ([
    "action", Some "edit";
    "title", Some (Title.to_string title);
    "text", Some text;
    "token", Some token.token;
    "md5", Some digest;
  ] @
    (arg_opt "summary" summary) @
    (arg_minor_flag minor) @
    (arg_watch_flag watch) @
    (arg_bool "bot" bot) @
    (arg_create_flag create))
  in
  Call.map get_edit_result (Call.http write_call)

let write_page (session : session) ?summary ?(minor = `DEFAULT) 
  ?(watch = `DEFAULT) ?(bot = false) ?(create = `DEFAULT) page text =
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
    "title", Some (Title.to_string page.page_title);
    "basetimestamp", Some ts;
    "text", Some text;
    "token", Some token.token;
    "md5", Some digest;
  ] @
    (arg_opt "summary" summary) @
    (arg_minor_flag minor) @
    (arg_watch_flag watch) @
    (arg_bool "bot" bot) @
    (arg_create_flag create))
  in
  Call.map get_edit_result (Call.http write_call)

let move_page session ?summary ?(watch = `DEFAULT) ?(rdr = true) 
  ?(subpages = true) ?(talk = true) ?(ignore_warnings = false)
  page title =
  let token = session#edit_token in
  let move_call = session#post_call ([
    "action", Some "move";
    "from", Some (Title.to_string page.page_title);
    "to", Some (Title.to_string title);
    "token", Some token.token;
  ] @
    (arg_opt "reason" summary) @
    (arg_watch_flag watch) @
    (arg_bool "noredirect" (not rdr)) @
    (arg_bool "movetalk" talk) @
    (arg_bool "movesubpages" subpages)
  )
  in
  Call.map get_move_result (Call.http move_call)

let move_title session ?summary ?(watch = `DEFAULT) ?(rdr = true) 
  ?(subpages = true) ?(talk = true) ?(ignore_warnings = false)
  src dst =
  let token = session#edit_token in
  let move_call = session#post_call ([
    "action", Some "move";
    "from", Some (Title.to_string src);
    "to", Some (Title.to_string dst);
    "token", Some token.token;
  ] @
    (arg_opt "reason" summary) @
    (arg_watch_flag watch) @
    (arg_bool "noredirect" (not rdr)) @
    (arg_bool "movetalk" talk) @
    (arg_bool "movesubpages" subpages)
  )
  in
  Call.map get_move_result (Call.http move_call)

let delete_title session ?summary ?(watch = `DEFAULT) title =
  let token = session#edit_token in
  let delete_call = session#post_call ([
    "action", Some "delete";
    "title", Some (Title.to_string title);
    "token", Some token.token;
  ] @
    (arg_opt "reason" summary) @
    (arg_watch_flag watch)
  )
  in
  Call.map get_delete_result (Call.http delete_call)

let upload_file (session : session) ?summary ?text ?(watch = `DEFAULT) 
  ?(ignore_warnings = false) title file =
  let token = session#edit_token in
  let upload_call = session#upload_call ([
    "action", Some "upload";
    "filename", Some title;
    "token", Some token.token;
  ] @
    (arg_opt "comment" summary) @
    (arg_opt "text" text) @
    (arg_bool "ignorewarnings" ignore_warnings) @
    (arg_watch_flag watch)
  ) file
  in
  Call.map get_upload_result (Call.http upload_call)
