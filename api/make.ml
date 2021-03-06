open Xml
open WTypes
open Datatypes
open Utils

(* TODO : separate path *)
let make_title tag data =
  if data.Xml.tag <> tag then
    raise (Call.API "Invalid argument: make_title");
  let l = data.Xml.attribs in
  let path = List.assoc "title" l in
  let ns = int_of_string (List.assoc "ns" l) in
  Title.make path ns

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
    page_id = Id.of_string (List.assoc "pageid" l);
    page_touched = Timestamp.of_string (List.assoc "touched" l);
    page_lastrevid = Id.of_string (List.assoc "lastrevid" l);
    page_length = int_of_string (List.assoc "length" l);
    page_redirect = List.mem_assoc "redirect" l;
    page_new = List.mem_assoc "new" l;
  }

let make_revision page data =
  if data.Xml.tag <> "rev" then
    raise (Call.API "Invalid argument: make_revision");
  let l = data.Xml.attribs in
  {
    rev_id = Id.of_string (List.assoc "revid" l);
    rev_page = page;
    rev_timestamp = Timestamp.of_string (List.assoc "timestamp" l);
    rev_user = List.assoc "user" l;
    rev_comment = (try List.assoc "comment" l with _ -> "");
    rev_minor = List.mem_assoc "minor" l;
  }

let make_diff data =
  if data.Xml.tag <> "diff" then
    raise (Call.API "Invalid argument: make_diff");
  let l = data.Xml.attribs in
  {
    diff_src = Id.of_string (List.assoc "from" l);
    diff_dst = Id.of_string (List.assoc "to" l);
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

let make_catinfo data =
  if data.Xml.tag <> "c" then
    raise (Call.API "Invalid argument: make_category_info");
  let l = data.Xml.attribs in
  let name = get_cdata data in
  let size = List.assoc "size" l in
  let pages = List.assoc "pages" l in
  let files = List.assoc "files" l in
  let subcats = List.assoc "subcats" l in {
    cat_name = name;
    cat_size = int_of_string size;
    cat_pages = int_of_string pages;
    cat_files = int_of_string files;
    cat_subcats = int_of_string subcats;
    cat_hidden = List.mem_assoc "hidden" l;
  }

let make_content data =
  if data.Xml.tag <> "rev" then
    raise (Call.API "Invalid argument: make_content");
  get_cdata data

let make_nsinfo aliases data =
  if data.Xml.tag <> "ns" then
    raise (Call.API "Invalid argument: make_nsinfo");
  let l = data.Xml.attribs in
  let id = List.assoc "id" l in
  let fold accu = function
  | Element ({ Xml.tag = "ns" } as elt) ->
    let vid = List.assoc "id" elt.Xml.attribs in 
    if vid = id then
      (get_cdata elt) :: accu
    else
      accu
  | _ -> accu
  in
  let case = match List.assoc "case" l with
  | "case-sensitive" -> true
  | _ -> false
  in
  let canonical =
    try Some (List.assoc "canonical" l)
    with Not_found -> None
  in
  {
    ns_id = int_of_string id;
    ns_name = get_cdata data;
    ns_subpages = List.mem_assoc "subpages" l;
    ns_case_sensitive = case;
    ns_canonical = canonical;
    ns_aliases = List.fold_left fold [] aliases;
    ns_content = List.mem_assoc "content" l;
  }

let make_statistics data =
  if data.Xml.tag <> "statistics" then
    raise (Call.API "Invalid argument: make_statistics");
  let l = data.Xml.attribs in
  let get_int key = int_of_string (List.assoc key l) in
  {
    stats_pages = get_int "pages";
    stats_articles = get_int "articles";
    stats_edits = get_int "edits";
    stats_images = get_int "images";
    stats_users = get_int "users";
    stats_activeusers = get_int "activeusers";
    stats_admins = get_int "admins";
    stats_jobs = get_int "jobs";
  }

let make_interwiki data =
  if data.Xml.tag <> "iw" then
    raise (Call.API "Invalid argument: make_interwiki");
  let l = data.Xml.attribs in
  {
    iw_prefix = List.assoc "prefix" l;
    iw_url = List.assoc "url" l;
    iw_local = List.mem_assoc "local" l;
  }

let get_continue data query =
  try
    let node = find_by_tag "query-continue" data.Xml.children in
    let node = find_by_tag query node.Xml.children in
    let arg = List.map (fun (n, v) -> n, Some v) node.Xml.attribs in
    `CONTINUE arg
  with _ -> `STOP

