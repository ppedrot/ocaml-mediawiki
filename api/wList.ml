open Xml
open Utils
open Datatypes
open Options
open Make

(* Built-in lists *)

(* A generic function to construct enumerations: [prop] is the name of the list
  property, [tag] is its two-letter tag, [make_fun] is the function that creates
  objects out of XML fragments, [opts] are the actual options passed to the call
  and [limit] the limit size of the result. *)

let rec query_list_aux prop tag make_fun session opts limit continue len =
  let process xml =
    let continue = get_continue xml prop in
    let xml = find_by_tag "query" xml.children in
    let data = try_children prop xml in
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
    | `STOP -> Call.return Enum.Stop
    | `CONTINUE continue ->
      query_list_aux prop tag make_fun session opts limit continue len
    in
    let rec flatten accu = function
    | [] -> accu
    | x :: l -> flatten (Call.return (Enum.Continue (x, accu))) l
    in
    flatten next pans
  in
  let query = [
    "action", Some "query";
    "list", Some prop;
    tag ^ "limit", Some "max";
  ] @ opts @ continue in
  let call = session#get_call query in
  Call.bind (Call.http call) process

let query_list prop tag make_fun session opts limit =
  query_list_aux prop tag make_fun session opts limit [] 0

(* All pages *)

let allpages (session : session) ?ns ?from ?upto ?prefix
  ?(rdrfilter = `ALL) ?minsize ?maxsize ?(order = `INCR) 
  ?(limit = max_int) () =
  let order = match order with
  | `INCR -> "ascending"
  | `DECR -> "descending"
  in
  let opts =
    ["apdir", Some order] @
    (arg_opt "apfrom" from) @
    (arg_opt "apto" upto) @
    (arg_opt "apprefix" prefix) @
    (arg_namespace "ap" ns) @
    (arg_redirect_filter_alt "ap" rdrfilter) @
    (arg_opt "apminsize" (may string_of_int minsize)) @
    (arg_opt "apmaxsize" (may string_of_int maxsize))
  in
  query_list "allpages" "ap" (make_title "p") session opts limit

(* All categories *)

let allcategories (session : session) ?from ?upto ?prefix ?(order = `INCR) 
  ?(limit = max_int) () =
  let order = match order with
  | `INCR -> "ascending"
  | `DECR -> "descending"
  in
  let opts =
    ["acdir", Some order] @
    ["acprop", Some "size|hidden"] @
    (arg_opt "acfrom" from) @
    (arg_opt "acto" upto) @
    (arg_opt "acprefix" prefix)
  in
  query_list "allcategories" "ac" make_catinfo session opts limit

(* Back links *)

let backlinks (session : session) ?(ns = [])
    ?(rdrfilter = `ALL) ?(rdr = false) ?(limit = max_int) title =
  let opts =
    (arg_title "bl" title) @
    (arg_namespaces "bl" ns) @
    (arg_bool "blredirect" rdr) @
    (arg_redirect_filter "bl" rdrfilter)
  in
  (* FIXME : parse redirlinks *)
  query_list "backlinks" "bl" (make_title "bl") session opts limit

(* Embedded pages *)

let embeddedin (session : session) ?(ns = []) ?(rdrfilter = `ALL) 
  ?(limit = max_int) title =
  let opts =
    (arg_title "ei" title) @
    (arg_namespaces "ei" ns) @
    (arg_redirect_filter "ei" rdrfilter)
  in
  query_list "embeddedin" "ei" (make_title "ei") session opts limit

(* External URL usage *)

(* FIXME: add protocol handling *)
let exturlusage (session : session) ?(ns = []) ?(limit = max_int) url =
  let opts = ["euquery", Some url] @ (arg_namespaces "eu" ns) in
  let make_url elt =
    let title = make_title "eu" elt in
    let url = List.assoc "url" elt.attribs in
    (title, url)
  in
  query_list "exturlusage" "eu" make_url session opts limit

(* Image usage *)

let imageusage (session : session) ?(ns = [])
    ?(rdrfilter:redirect_filter = `ALL) ?(rdr = false) ?(limit = max_int)
    title =
  let opts =
    (arg_title "iu" title) @
    (arg_namespaces "iu" ns)@
    (arg_bool "iuredirect" rdr) @
    (arg_redirect_filter "iu" rdrfilter)
  in
  query_list "imageusage" "iu" (make_title "iu") session opts limit

(* Recent changes *)

let recentchanges (session : session) ?fromts ?uptots ?(ns = []) 
  ?(order = `DECR) ?(usrfilter = `ALL) ?(limit = max_int) () =
  let order_arg = match order with
  | `INCR -> "newer"
  | `DECR -> "older"
  in
  let opts =
    (arg_timestamp "rcstart" fromts) @
    (arg_timestamp "rcend" uptots) @
    (arg_namespaces "rc" ns) @
    ["rcdir", Some order_arg] @
    ["rcprop", Some "user|comment|flags|timestamp|title|ids|loginfo"] @
    (arg_user_filter "rc" usrfilter)
  in
  let try_assoc k l = try Some (List.assoc k l) with Not_found -> None in
  let get_type = function
  | "edit" -> `EDIT
  | "log" -> `LOG
  | "new" -> `NEW
  | _ -> invalid_arg "get_type"
  in
  let make_rc elt =
    let attribs = elt.Xml.attribs in
    let get_val v = List.assoc v attribs in
    {
      rc_id = id_of_string (get_val "rcid");
      rc_type = get_type (get_val "type");
      rc_title = {
        title_path = get_val "title";
        title_namespace = int_of_string (get_val "ns")
      };
      rc_user = get_val "user";
      rc_comment = get_val "comment";
      rc_minor = List.mem_assoc "minor" attribs;
      rc_anon = List.mem_assoc "anon" attribs;
      rc_oldrevid = id_of_string (get_val "old_revid");
      rc_newrevid = id_of_string (get_val "revid");
      rc_timestamp = parse_timestamp (get_val "timestamp");
      rc_logtype = try_assoc "logtype" attribs;
      rc_logaction = try_assoc "logaction" attribs;
    }
  in
  query_list "recentchanges" "rc" make_rc session opts limit

(* Search *)

let search (session : session) ?(ns = []) ?(what = `TEXT) ?(rdr = false)
  ?(limit = max_int) text =
  let what = match what with
  | `TEXT -> "text"
  | `TITLE -> "title"
  in
  let opts =
    ["srwhat", Some what] @
    ["srsearch", Some text] @
    (arg_bool "srredirects" rdr) @
    (arg_namespaces "sr" ns)
  in
  query_list "search" "sr" (make_title "p") session opts limit
