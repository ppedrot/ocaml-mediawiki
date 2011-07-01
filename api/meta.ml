open Xml
open Datatypes
open Utils
open Make

let namespaces session =
  let process xml =
    let xml = find_by_tag "query" xml.Xml.children in
    let nss = try_children "namespaces" xml in
    let nsaliases = try_children "namespacealiases" xml in
    let fold accu = function
    | Element ({ Xml.tag = "ns" } as elt) ->
      let nsinfo = make_nsinfo nsaliases elt in
      nsinfo :: accu
    | _ -> accu
    in
    let ans = List.fold_left fold [] nss in
    Call.return ans
  in
  let call = session#get_call [
    "action", Some "query";
    "meta", Some "siteinfo";
    "siprop", Some "namespaces|namespacealiases";
  ] in
  Call.bind (Call.http call) process
