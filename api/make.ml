open Xml
open Datatypes
open Utils

(* TODO : separate path *)
let make_title tag data =
  if data.Xml.tag <> tag then
    raise (Call.API "Invalid argument: make_title");
  let l = data.Xml.attribs in
  {
    title_path = List.assoc "title" l;
    title_namespace = int_of_string (List.assoc "ns" l);
  }

let make_page data =
  if data.Xml.tag <> "page" then
    raise (Call.API "Invalid argument: make_page");
  let l = data.Xml.attribs in
  if List.mem_assoc "missing" l then
    try `MISSING (make_title "page" data)
    with _ -> `INVALID
  else if List.mem_assoc "invalid" l then `INVALID
  else `EXISTING {
    page_title = make_title "page" data;
    page_id = id_of_string (List.assoc "pageid" l);
    page_touched = parse_timestamp (List.assoc "touched" l);
    page_lastrevid = id_of_string (List.assoc "lastrevid" l);
    page_length = int_of_string (List.assoc "length" l);
    page_redirect = List.mem_assoc "redirect" l;
    page_new = List.mem_assoc "new" l;
  }

let make_revision page data =
  if data.Xml.tag <> "rev" then
    raise (Call.API "Invalid argument: make_revision");
  let l = data.Xml.attribs in
  {
    rev_id = id_of_string (List.assoc "revid" l);
    rev_page = page;
    rev_timestamp = parse_timestamp (List.assoc "timestamp" l);
    rev_user = List.assoc "user" l;
    rev_comment = (try List.assoc "comment" l with _ -> "");
    rev_minor = List.mem_assoc "minor" l;
  }

let make_diff data =
  if data.Xml.tag <> "diff" then
    raise (Call.API "Invalid argument: make_diff");
  let l = data.Xml.attribs in
  {
    diff_src = id_of_string (List.assoc "from" l);
    diff_dst = id_of_string (List.assoc "to" l);
    diff_val = get_cdata data;
  }

let make_link = make_title "pl"

let make_langlink data =
  if data.Xml.tag <> "ll" then
    raise (Call.API "Invalid argument: make_langlink");
  {
    lang_title = get_cdata data;
    lang_language = List.assoc "lang" data.Xml.attribs;
  }

let make_extlink data =
  if data.Xml.tag <> "el" then
    raise (Call.API "Invalid argument: make_extlink");
  get_cdata data

let make_imagelink = make_title "im"

let make_templatelink = make_title "tl"

(* FIXME *)
let make_category data =
  if data.Xml.tag <> "cl" then
    raise (Call.API "Invalid argument: make_category");
  List.assoc "title" data.Xml.attribs

let make_content data =
  if data.Xml.tag <> "rev" then
    raise (Call.API "Invalid argument: make_content");
  get_cdata data

let get_continue data query =
  try
    let node = find_by_tag "query-continue" data.Xml.children in
    let node = find_by_tag query node.Xml.children in
    let arg = List.map (fun (n, v) -> n, Some v) node.Xml.attribs in
    `CONTINUE arg
  with _ -> `STOP
