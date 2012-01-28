open WTypes
open Datatypes

(** {1 Library functions} *)

val make_title : string -> Xml.elt -> title

val make_page : Xml.elt ->
  [> `EXISTING of page | `INVALID | `MISSING of title ]

val make_revision : page Id.t -> Xml.elt -> revision

val make_diff : Xml.elt -> diff

val make_link : Xml.elt -> title

val make_langlink : Xml.elt -> langlink

val make_extlink : Xml.elt -> string

val make_imagelink : Xml.elt -> title

val make_templatelink : Xml.elt -> title

val make_category : Xml.elt -> string

val make_catinfo : Xml.elt -> category_info

val make_content : Xml.elt -> string

val make_nsinfo : Xml.xml list -> Xml.elt -> namespace_info

val get_continue : Xml.elt -> string ->
  [> `CONTINUE of (string * string option) list | `STOP ]
