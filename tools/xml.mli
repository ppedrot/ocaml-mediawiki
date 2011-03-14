type xml =
| Element of elt
| CData of string

and elt = {
  tag : string;
  attribs : (string * string) list;
  children : xml list
}

val tag : xml -> string
val children : xml -> xml list
val attribs : xml -> (string * string) list

val find_by_tag : string -> xml list -> elt
val find_by_attrib : string -> string -> xml list -> elt
val try_children : string -> elt -> xml list

val assoc_attrib : string -> xml -> string

type xml_parser

val parser_create : unit -> xml_parser
val parse : xml_parser -> string -> unit
val parse_sub : xml_parser -> string -> int -> int -> unit
val final : xml_parser -> elt

val parse_string : string -> elt
val parse_in_obj_channel : Netchannels.in_obj_channel -> elt

val print_xml : out_channel -> elt -> unit
