open Printf
open Expat

type xml =
| Element of elt
| CData of string

and elt = {
  tag : string;
  attribs : (string * string) list;
  children : xml list
}

type xml_parser = (expat_parser * (unit -> elt))

let rec find_by_tag tag = function
| [] -> raise Not_found
| Element elt :: t ->
    if elt.tag = tag then elt
    else find_by_tag tag t
| _ :: t -> find_by_tag tag t

let rec find_by_attrib attr value = function
| [] -> raise Not_found
| Element elt :: t ->
    if List.mem (attr, value) elt.attribs then elt
    else find_by_attrib attr value t
| _ :: t -> find_by_attrib attr value t

let try_children tag xml =
  try
    let xml = find_by_tag tag xml.children in
    xml.children
  with Not_found -> []

let tag = function
| Element elt -> elt.tag
| _ -> invalid_arg "Xml.tag"

let children = function
| Element elt -> elt.children
| _ -> invalid_arg "Xml.children"

let attribs = function
| Element elt -> elt.attribs
| _ -> invalid_arg "Xml.attrs"

let assoc_attrib key xml = match xml with
| Element elt -> List.assoc key elt.attribs
| _ -> invalid_arg "Xml.assoc_attrib"

let add_child node (child : xml) =
  let obj = Obj.repr [child] in
  match node.children with
  | [] -> Obj.set_field (Obj.repr node) 2 obj
  | _ as l ->
    let rec append x l = match l with
    | [] -> assert false
    | t :: [] -> Obj.set_field (Obj.repr l) 1 obj
    | t :: q -> append x q
    in
    append child l

let parser_create () =
  let p = parser_create (Some "UTF-8") in
  let ans = ref None in
  let nodes = Stack.create () in
  let pop () = Stack.pop nodes in
  let push x = Stack.push x nodes in
  let start_elt tag attribs =
    let xml = {
      tag = tag;
      attribs = attribs;
      children = [];
    } in
    if not (Stack.is_empty nodes) then
      add_child (Stack.top nodes) (Element xml);
    if !ans = None then
      ans := Some xml;
    push xml
  in
  let end_elt tag =
    ignore (pop ())
  in
  let char_data data =
    let cdata = CData data in
    if not (Stack.is_empty nodes) then
      add_child (Stack.top nodes) cdata
  in
  set_start_element_handler p start_elt;
  set_end_element_handler p end_elt;
  set_character_data_handler p char_data;
  p, (fun () -> match !ans with
  | None -> assert false
  | Some xml -> xml)

let parse (p, _) s = parse p s

let parse_sub (p, _) s off len = parse_sub p s off len

let final (p, f) = final p; f ()

let parse_string s =
  let p = parser_create () in
  parse p s; final p

let parse_in_obj_channel (ic : Netchannels.in_obj_channel) =
  let len = 1024 in
  let buf = String.create len in
  let p = parser_create () in
  let brk = ref true in
  while !brk do
    try
      let off = ic#input buf 0 len in
      parse_sub p buf 0 off
    with End_of_file -> brk := false
  done;
  final p

(* Escape reserved characters of XML from an UTF-8 string *)
let print_escaped out s =
  let iter c = match c with
  | '<' -> output_string out "&lt;"
  | '>' -> output_string out "&gt;"
  | '&' -> output_string out "&amp;"
  | '\'' -> output_string out "&apos;"
  | '\"' -> output_string out "&quot;"
  | _ -> output_char out c
  in
  String.iter iter s

let rec print_elt chan elt = match elt.children with
| [] ->
  fprintf chan "<%s%a/>" elt.tag print_attribs elt.attribs
| _ ->
  fprintf chan "<%s%a>%a</%s>" elt.tag print_attribs elt.attribs
    print_data elt.children elt.tag

and print_data chan = function
| [] -> ()
| Element elt :: q -> print_elt chan elt; print_data chan q
| CData c :: q -> print_escaped chan c; print_data chan q

and print_attribs chan = function
| [] -> ()
| (id, value) :: q ->
  fprintf chan " %s=\"%a\"%a" id print_escaped value print_attribs q

let print_xml chan xml =
  let () = fprintf chan "<?xml version=\"1.0\"?>" in
  print_elt chan xml
