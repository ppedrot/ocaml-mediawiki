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
    ["apfrom", from] @
    ["apto", upto] @
    ["apprefix", prefix] @
    (arg_namespace "ap" ns) @
    (arg_redirect_filter_alt "ap" rdrfilter) @
    ["apminsize", may string_of_int minsize] @
    ["apmaxsize", may string_of_int maxsize]
  in
  query_list "allpages" "ap" (make_title "p") session opts limit

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
