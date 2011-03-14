open Netmime

type t

val set_cookie : #mime_header -> t list -> unit
val get_cookie : #mime_header -> t list
val get_set_cookie : #mime_header -> t list
