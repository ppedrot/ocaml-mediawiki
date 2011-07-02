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

let userinfo session =
  let process xml =
    let xml = find_by_tag "query" xml.Xml.children in
    let xml = find_by_tag "userinfo" xml.Xml.children in
    let attrs = xml.Xml.attribs in
    let groups = try_children "groups" xml in
    let fold accu = function
    | Xml.Element ({ tag = "g" } as elt) -> (get_cdata elt) :: accu
    | _ -> accu
    in
    let info = {
      user_id = id_of_string (List.assoc "id" attrs);
      user_name = List.assoc "name" attrs;
      user_anon = List.mem_assoc "anon" attrs;
      user_groups = List.fold_left fold [] groups;
    } in
    Call.return info
  in
  let call = session#get_call [
    "action", Some "query";
    "meta", Some "userinfo";
    "uiprop", Some "groups";
  ] in
  Call.bind (Call.http call) process
