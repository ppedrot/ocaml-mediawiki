open Netmime

type t = Nethttp.cookie

val set_cookie : #mime_header -> t list -> unit

val get_set_cookie : #mime_header -> t list
