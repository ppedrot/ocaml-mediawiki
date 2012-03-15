open Xml
open WTypes
open Datatypes
open Options
open Utils
open Make

(* Titles *)

let dummy_title = {
  title_path = "";
  title_namespace = 0;
}

(* TODO *)
let check_title t =
  if String.contains t '|' || String.contains t '#'
  then invalid_arg "Malformed title"

(* Pages *)

let dummy_page id = {
  page_title = dummy_title;
  page_id = id;
  page_touched = parse_timestamp "0000-00-00T00:00:00Z";
  page_lastrevid = Id.cast 0L;
  page_length = 0;
  page_redirect = false;
  page_new = false;
}

(* TODO : patch for interwikis + redirects *)
let rec of_titles_aux (session : session) titles =
  (* Reverse mapping of normalized titles to provided ones. *)
  let get_normalized xml =
    let data = try_children "normalized" xml in
    let fold accu = function
    | Xml.Element { Xml.tag = "n"; Xml.attribs = attrs; } ->
      let nfrom = List.assoc "from" attrs in
      let nto = List.assoc "to" attrs in
      Map.add nto nfrom accu
    | _ -> accu
    in
    List.fold_left fold Map.empty data
  in
  let process xml =
    let xml = find_by_tag "query" xml.Xml.children in
    let normalized = get_normalized xml in
    let pages =
      let node = find_by_tag "pages" xml.Xml.children in
      node.Xml.children
    in
    let map = function
    | Xml.Element ({Xml.tag = "page"} as p) ->
      let page = make_page p in
      let norm_title = List.assoc "title" p.Xml.attribs in
      let orig_title =
        try Map.find norm_title normalized
        with Not_found -> norm_title
      in
      Some (orig_title, page)
    | _ -> None
    in
    let ans = BatList.filter_map map pages in
    (* MediaWiki may only answer partially due to limits so retry *)
    let redo = BatList.filter (fun t -> not (List.mem_assoc t ans)) titles in
    Enum.append (Enum.of_list ans) (of_titles_aux session redo)
  in
  if titles = [] then Enum.empty ()
  else
    let call = session#get_call [
      "action", Some "query";
      "prop", Some "info";
      "titles", Some (String.concat "|" titles);
    ] in
    Enum.collapse (Call.map process (Call.http call))

let of_titles session titles =
  let () = List.iter check_title titles in
  (* discard the invalid and missing titles *)
  let map = function
  | title, `EXISTING page -> Call.return (Some (title, page))
  | _ -> Call.return None
  in
  Enum.filter_map map (of_titles_aux session titles)

let normalize session titles =
  let () = List.iter check_title titles in
  (* discard the invalid and missing titles *)
  let map = function
  | title, `EXISTING page -> Call.return (Some (title, page.page_title))
  | title, `MISSING mtitle -> Call.return (Some (title, mtitle))
  | _ -> Call.return None
  in
  Enum.filter_map map (of_titles_aux session titles)

let rec of_pageids_aux session pageids =
  let process xml =
    let xml = find_by_tag "query" xml.Xml.children in
    let pages =
      let node = find_by_tag "pages" xml.Xml.children in
      node.Xml.children
    in
    let map = function
    | Xml.Element ({Xml.tag = "page"} as p) ->
      let ans = make_page p in
      let id = Id.of_string (List.assoc "pageid" p.Xml.attribs) in
      Some (id, ans)
    | _ -> None
    in
    let ans = BatList.filter_map map pages in
    let redo = BatList.filter (fun id -> not (List.mem_assoc id ans)) pageids in
    Enum.append (Enum.of_list ans) (of_pageids_aux session redo)
  in
  if pageids = [] then Enum.empty ()
  else
    let sids = List.rev_map Id.to_string pageids in
    let call = session#get_call [
      "action", Some "query";
      "prop", Some "info";
      "pageids", Some (String.concat "|" sids);
    ] in
    Enum.collapse (Call.map process (Call.http call))

let of_pageids (session : session) pageids =
  (* discard the invalid and missing ids *)
  let map = function
  | id, `EXISTING page -> Call.return (Some (id, page))
  | _ -> Call.return None
  in
  Enum.filter_map map (of_pageids_aux session pageids)

(* Revisions *)

let dummy_revision id = {
  rev_id = id;
  rev_page = Id.cast 0L;
  rev_timestamp = parse_timestamp "0000-00-00T00:00:00Z";
  rev_user = "";
  rev_comment = "";
  rev_minor = false;
}

let rec of_revids_aux session revids =
  let process xml =
    let xml = find_by_tag "query" xml.Xml.children in
    let badids = try_children "badrevids" xml in
    let pages = try_children "pages" xml in
    let fold_badid accu = function
    | Xml.Element r ->
      let id = List.assoc "revid" r.Xml.attribs in
      Set.add (Id.of_string id) accu
    | _ -> accu
    in
    let filter_pages = function
    | Xml.Element ({Xml.tag = "page"} as p) ->
      let pageid = Id.of_string (List.assoc "pageid" p.Xml.attribs) in
      let revs = try_children "revisions" p in
      let map = function
      | Xml.Element ({Xml.tag = "rev"} as r) ->
        let rev = make_revision pageid r in
        Some (rev.rev_id, rev)
      | _ -> None
      in
      Some (BatList.filter_map map revs)
    | _ -> None
    in
    let ans = BatList.concat (BatList.filter_map filter_pages pages) in
    let invalid = List.fold_left fold_badid Set.empty badids in
    let filter t = not (List.mem_assoc t ans) && not (Set.mem t invalid) in
    let redo = BatList.filter filter revids in
    Enum.append (Enum.of_list ans) (of_revids_aux session redo)
  in
  if revids = [] then Enum.empty ()
  else
    let sids = List.rev_map Id.to_string revids in
    let call = session#get_call [
      "action", Some "query";
      "prop", Some "revisions";
      "revids", Some (String.concat "|" sids);
    ] in
    Enum.collapse (Call.map process (Call.http call))

let of_revids session revids =
  of_revids_aux session revids

(* Content *)

let rec content_aux session revids =
  let process xml =
    let xml = find_by_tag "query" xml.Xml.children in
    let badids = try_children "badrevids" xml in
    let pages = try_children "pages" xml in
    let fold_badid accu = function
    | Xml.Element ({Xml.tag = "rev"} as r) ->
      let id = List.assoc "revid" r.Xml.attribs in
      Set.add (Id.of_string id) accu
    | _ -> accu
    in
    let filter_pages = function
    | Xml.Element ({Xml.tag = "page"} as p) ->
      let revs = try_children "revisions" p in
      let map = function
      | Xml.Element ({Xml.tag = "rev"} as r) ->
        let content = make_content r in
        let id = List.assoc "revid" r.Xml.attribs in
        Some ((Id.of_string id), content)
      | _ -> None
      in
      Some (BatList.filter_map map revs)
    | _ -> None
    in
    (* Get content of valid revids *)
    let ans = BatList.concat (BatList.filter_map filter_pages pages) in
    (* Get rid of invalid revids *)
    let invalid = List.fold_left fold_badid Set.empty badids in
    let filter t = not (List.mem_assoc t ans) && not (Set.mem t invalid) in
    let redo = BatList.filter filter revids in
    Enum.append (Enum.of_list ans) (content_aux session redo)
  in
  if revids = [] then Enum.empty ()
  else
    let sids = BatList.map Id.to_string revids in
    let call = session#get_call [
      "action", Some "query";
      "prop", Some "revisions";
      "revids", Some (String.concat "|" sids);
      "rvprop", Some "ids|content";
    ] in
    Enum.collapse (Call.map process (Call.http call))

let content session revs =
  let revids = BatList.map (fun r -> r.rev_id) revs in
  content_aux session revids

(* Diffs *)

let diff session src dst =
  let dst = match dst with
  | `ID id -> Id.to_string id
  | `PREVIOUS -> "prev"
  | `CURRENT -> "cur"
  | `NEXT -> "next"
  in
  let process xml =
    let xml = find_by_tag "query" xml.Xml.children in
(*     let badids = try_children "badrevids" xml in *)
    let pages = try_children "pages" xml in
    let page = match pages with
    | Element p :: _ -> p
    | _ -> raise (Call.API "diff: No such revid")
    in
    let revs = find_by_tag "revisions" page.Xml.children in
    let rev = find_by_tag "rev" revs.Xml.children in
    let diff = find_by_tag "diff" rev.Xml.children in
    Call.return (make_diff diff)
  in
  let call = session#get_call [
    "action", Some "query";
    "prop", Some "revisions";
    "revids", Some (Id.to_string src);
    "rvdiffto", Some dst;
  ] in
  Call.bind (Call.http call) process

(* Generic parser of list results *)

let rec query_list_aux prop tag make_fun session pageid opts limit continue len =
  let process xml =
    let continue = get_continue xml prop in
    let xml = find_by_tag "query" xml.children in
    let pages = find_by_tag "pages" xml.Xml.children in
    let page = find_by_attrib "pageid" pageid pages.Xml.children in
    let data = try_children prop page in
    let rec fold accu len = function
    | [] -> (accu, len)
    | Xml.Element elt :: l ->
      if limit <= len then (accu, len)
      else fold (make_fun elt :: accu) (succ len) l
    | _ :: l ->
    (* Whenever the answer is not an element, discard it *)
      fold accu len l
    in
    (* elements are reversed *)
    let (pans, len) = fold [] len data in
    let continue = if limit <= len then `STOP else continue in
    let next = match continue with
    | `STOP -> Enum.empty ()
    | `CONTINUE continue ->
      query_list_aux prop tag make_fun session pageid opts limit continue len
    in
    Enum.append (Enum.of_list pans) next
  in
  let query = [
    "action", Some "query";
    "prop", Some prop;
    tag ^ "limit", Some "max";
    "pageids", Some pageid;
  ] @ opts @ continue in
  let call = session#get_call query in
  Enum.collapse (Call.map process (Call.http call))

(* [prop] is the name of the property, [tag] its short name, [make_fun] the
   function used to create data from XML *)
let query_list prop tag make_fun session page opts limit =
  let pageid = Id.to_string page.page_id in
  query_list_aux prop tag make_fun session pageid opts limit [] 0

(* Revisions *)

let revisions session ?fromid ?uptoid ?fromts ?uptots ?(order = `DECR) 
  ?(usrfilter = `ALL) ?(limit = max_int) page =
  let order_arg = match order with
  | `INCR -> ["rvdir", Some "newer"]
  | `DECR -> ["rvdir", Some "older"]
  in
  let opts = (arg_timestamp "rvend" fromts)
    @ (arg_timestamp "rvstart" uptots) @ (arg_id "rvendid" fromid)
    @ (arg_id "rvstartid" uptoid) @ (arg_user_filter "rv" usrfilter)
    @ order_arg
  in
  let make_fun = make_revision page.page_id in
  query_list "revisions" "rv" make_fun session page opts limit

(* Various stuff that return lists *)

let links s ?(ns = []) ?(limit = max_int) p =
  query_list "links" "pl" make_link s p (arg_namespaces "pl" ns) limit

let langlinks s ?(limit = max_int) p =
  query_list "langlinks" "ll" make_langlink s p [] limit

let images s ?(limit = max_int) p =
  query_list "images" "im" make_imagelink s p [] limit

let templates s ?(ns = []) ?(limit = max_int) p =
  query_list "templates" "tl" make_templatelink s p (arg_namespaces "tl" ns) limit

(* FIXME: add a real parser and options *)
let categories s ?(limit = max_int) p =
  query_list "categories" "cl" make_category s p [] limit

(* FIXME: must use eloffset instead of elcontinue *)
let external_links s ?(limit = max_int) p =
  query_list "extlinks" "el" make_extlink s p [] limit
