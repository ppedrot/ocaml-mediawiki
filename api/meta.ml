open Utils
open Datatypes
open Xml

let make_ns aliases data =
  assert false

let namespaces session =
  let process xml =
    let xml = find_by_tag "query" xml.Xml.children in
    let nss = try_children "namespaces" xml in
    let nsaliases = try_children "namespacesaliases" in
    Call.return (List.map (make_ns nsaliases) nss)
  in
  let call = session#get_call [
    "action", Some "query";
    "meta", Some "siteinfo";
    "siprop", Some "namespaces|namespacealiases";
  ] in
  Call.bind (Call.http call) process
