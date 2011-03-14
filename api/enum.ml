open Xml
open Utils
open Datatypes
open Options
open Prop

(* Built-in lists *)

let rec query_list_aux prop tag make_fun session opts continue accu =
  let process xml =
    let continue = get_continue xml prop in
    let xml = find_by_tag "query" xml.Xml.children in
    let data = try_children prop xml in
    let fold accu = function
    | Xml.Element elt -> make_fun elt :: accu
    | _ -> accu
    in
    let accu = List.fold_left fold accu data in
    query_list_aux prop tag make_fun session opts continue accu
  in
  let query = [
    "action", Some "query";
    "list", Some prop;
    tag ^ "limit", Some "max";
  ] @ opts in
  match continue with
  | `STOP -> Call.return accu
  | `START ->
    let call = session#get_call query in
    Call.bind (Call.http call) process
  | `CONTINUE arg ->
    let call = session#get_call (query @ arg) in
    Call.bind (Call.http call) process

let query_list prop tag make_fun session opts =
  query_list_aux prop tag make_fun session opts `START []

(* Back links *)

let backlinks (session : session) ?ns
    ?(rdrfilter = `ALL) ?(rdr = false) title =
  let opts = ["bltitle", Some (string_of_title title)] @ (arg_namespace ns)
    @ (arg_bool "redirect" rdr)
  in
  query_list "backlinks" "bl" (make_title "bl") session opts
