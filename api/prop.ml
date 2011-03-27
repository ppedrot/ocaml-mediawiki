open Xml
open Datatypes
open Options
open Utils

(* Titles *)

let dummy_title = {
  title_path = "";
  title_namespace = 0;
}

(* TODO *)
let check_title t =
  if String.contains t '|' || String.contains t '#'
  then invalid_arg "Malformed title"

let get_element = function
| Xml.Element elt -> elt
| _ -> raise (Call.API "Invalid API answer")

let buf = Buffer.create 64

let get_cdata data =
  let iter = function
  | Xml.CData s -> Buffer.add_string buf s
  | _ -> ()
  in
  let () = List.iter iter data.Xml.children in
  let ans = Buffer.contents buf in
  let () = Buffer.clear buf in
  ans

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

(* Pages *)

let dummy_page id = {
  page_title = dummy_title;
  page_id = id;
  page_touched = parse_timestamp "0000-00-00T00:00:00Z";
  page_lastrevid = 0L;
  page_length = 0;
  page_redirect = false;
  page_new = false;
}

(* TODO : patch for interwikis + redirects *)
let rec of_titles_aux (session : session) titles accu =
  (* Reverse mapping of normalized titles to provided ones. *)
  let get_normalized xml =
    let data = try_children "normalized" xml in
    let fold accu = function
    | Xml.Element { Xml.tag = "n"; Xml.attribs = attrs; } ->
      let nfrom = List.assoc "from" attrs in
      let nto = List.assoc "to" attrs in
      MapString.add nto nfrom accu
    | _ -> accu
    in
    List.fold_left fold MapString.empty data
  in
  let process xml =
    let xml = find_by_tag "query" xml.Xml.children in
    let normalized = get_normalized xml in
    let pages =
      let node = find_by_tag "pages" xml.Xml.children in
      node.Xml.children
    in
    let fold accu = function
    | Xml.Element ({Xml.tag = "page"} as p) ->
      let page = make_page p in
      let norm_title = List.assoc "title" p.Xml.attribs in
      let orig_title =
        try MapString.find norm_title normalized
        with Not_found -> norm_title
      in
      MapString.add orig_title page accu
    | _ -> accu
    in
    let ans = List.fold_left fold accu pages in
    (* MediaWiki may only answer partially due to limits so retry *)
    let redo = List.filter (fun t -> not (MapString.mem t ans)) titles in
    of_titles_aux session redo ans
  in
  if titles = [] then
    Call.return accu
  else
    let call = session#get_call [
      "action", Some "query";
      "prop", Some "info";
      "titles", Some (String.concat "|" titles);
    ] in
    Call.bind (Call.http call) process

let of_titles session titles =
  let () = List.iter check_title titles in
  of_titles_aux session titles MapString.empty

let rec of_pageids_aux session pageids accu =
  let process xml =
    let xml = find_by_tag "query" xml.Xml.children in
    let pages =
      let node = find_by_tag "pages" xml.Xml.children in
      node.Xml.children
    in
    let fold accu = function
    | Xml.Element ({Xml.tag = "page"} as p) ->
      let ans = make_page p in
      let id = id_of_string (List.assoc "pageid" p.Xml.attribs) in
      MapID.add id ans accu
    | _ -> accu
    in
    let ans = List.fold_left fold accu pages in
    let redo = List.filter (fun id -> not (MapID.mem id ans)) pageids in
    of_pageids_aux session redo ans
  in
  if pageids = [] then
    Call.return accu
  else
    let sids = List.rev_map string_of_id pageids in
    let call = session#get_call [
      "action", Some "query";
      "prop", Some "info";
      "pageids", Some (String.concat "|" sids);
    ] in
    Call.bind (Call.http call) process

let of_pageids session pageids =
  of_pageids_aux session pageids MapID.empty

(* Revisions *)

let dummy_revision id = {
  rev_id = id;
  rev_page = 0L;
  rev_timestamp = parse_timestamp "0000-00-00T00:00:00Z";
  rev_user = "";
  rev_comment = "";
  rev_minor = false;
}

let rec of_revids_aux session revids invalid accu =
  let process xml =
    let xml = find_by_tag "query" xml.Xml.children in
    let badids = try_children "badrevids" xml in
    let pages = try_children "pages" xml in
    let fold_badid accu = function
    | Xml.Element r ->
      let id = List.assoc "revid" r.Xml.attribs in
      SetID.add (id_of_string id) accu
    | _ -> accu
    in
    let fold_pages accu = function
    | Xml.Element ({Xml.tag = "page"} as p) ->
      let pageid = id_of_string (List.assoc "pageid" p.Xml.attribs) in
      let revs = try_children "revisions" p in
      let fold accu = function
      | Xml.Element ({Xml.tag = "rev"} as r) ->
        let rev = make_revision pageid r in
        MapID.add rev.rev_id rev accu
      | _ -> accu
      in
      List.fold_left fold accu revs
    | _ -> accu
    in
    let accu = List.fold_left fold_pages accu pages in
    let invalid = List.fold_left fold_badid invalid badids in
    let filter t = not (MapID.mem t accu) && not (SetID.mem t invalid) in
    let redo = List.filter filter revids in
    of_revids_aux session redo invalid accu
  in
  if revids = [] then
    Call.return accu
  else
    let sids = List.rev_map string_of_id revids in
    let call = session#get_call [
      "action", Some "query";
      "prop", Some "revisions";
      "revids", Some (String.concat "|" sids);
    ] in
    Call.bind (Call.http call) process

let of_revids session revids =
  of_revids_aux session revids SetID.empty MapID.empty

(* Content *)

let rec content_aux session revids invalid accu =
  let process xml =
    let xml = find_by_tag "query" xml.Xml.children in
    let badids = try_children "badrevids" xml in
    let pages = try_children "pages" xml in
    let fold_badid accu = function
    | Xml.Element ({Xml.tag = "rev"} as r) ->
      let id = List.assoc "revid" r.Xml.attribs in
      SetID.add (id_of_string id) accu
    | _ -> accu
    in
    let fold_pages accu = function
    | Xml.Element ({Xml.tag = "page"} as p) ->
      let revs = try_children "revisions" p in
      let fold accu = function
      | Xml.Element ({Xml.tag = "rev"} as r) ->
        let content = make_content r in
        let id = List.assoc "revid" r.Xml.attribs in
        MapID.add (id_of_string id) (content) accu
      | _ -> accu
      in
      List.fold_left fold accu revs
    | _ -> accu
    in
    (* Get content of valid revids *)
    let accu = List.fold_left fold_pages accu pages in
    (* Get rid of invalid revids *)
    let invalid = List.fold_left fold_badid invalid badids in
    let filter t = not (MapID.mem t accu) && not (SetID.mem t invalid) in
    let redo = List.filter filter revids in
    content_aux session redo invalid accu
  in
  if revids = [] then
    Call.return accu
  else
    let sids = List.map string_of_id revids in
    let call = session#get_call [
      "action", Some "query";
      "prop", Some "revisions";
      "revids", Some (String.concat "|" sids);
      "rvprop", Some "ids|content";
    ] in
    Call.bind (Call.http call) process

let content session revs =
  let revids = List.map (fun r -> r.rev_id) revs in
  content_aux session revids SetID.empty MapID.empty

(* Generic parser of list results *)

let rec generic_list_aux prop tag make_fun opts session pageid continue accu =
  let process xml =
    let continue = get_continue xml prop in
    let xml = find_by_tag "query" xml.Xml.children in
    let pages = find_by_tag "pages" xml.Xml.children in
    let page = find_by_attrib "pageid" pageid pages.Xml.children in
    let data = try_children prop page in
    let fold accu = function
    | Xml.Element elt -> make_fun elt :: accu
    | _ -> accu
    in
    let accu = List.fold_left fold accu data in
    generic_list_aux prop tag make_fun opts session pageid continue accu
  in
  let query = [
    "action", Some "query";
    "prop", Some prop;
    tag ^ "limit", Some "max";
    "pageids", Some pageid
  ] @ opts in
  match continue with
  | `STOP -> Call.return accu
  | `START ->
    let call = session#get_call query in
    Call.bind (Call.http call) process
  | `CONTINUE arg ->
    let call = session#get_call (query @ arg) in
    Call.bind (Call.http call) process

(* [prop] is the name of the property, [tag] its short name, [make_fun] the
   function used to create data from XML *)
let generic_list prop tag make_fun opts session page =
  let pageid = string_of_id page.page_id in
  generic_list_aux prop tag make_fun opts session pageid `START []

(* Revisions *)

let revisions session ?fromid ?uptoid ?fromts ?uptots ?(usrfilter = `ALL) page =
  let pageid = string_of_id page.page_id in
  let opts = (arg_timestamp "rvend" fromts)
    @ (arg_timestamp "rvstart" uptots) @ (arg_id "rvendid" fromid)
    @ (arg_id "rvstartid" uptoid) @ (arg_user_filter "rv" usrfilter) in
  let make = make_revision page.page_id in
  let call = generic_list_aux "revisions" "rv" make opts in
  call session pageid `START []

(* Various stuff that return lists *)

let links s ?(ns = []) =
  generic_list "links" "pl" make_link (arg_namespaces "pl" ns) s

let langlinks =
  generic_list "langlinks" "ll" make_langlink []

let images =
  generic_list "images" "im" make_imagelink []

let templates s ?(ns = []) =
  generic_list "templates" "tl" make_templatelink (arg_namespaces "tl" ns) s

let categories =
  generic_list "categories" "cl" make_category []

let external_links =
  generic_list "extlinks" "el" make_extlink []

