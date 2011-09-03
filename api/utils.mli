open Datatypes

type mw_version = { mw_major : int; mw_minor : int; }

val user_agent : string

(** {1 Identifiers} *)

val id_of_string : string -> id
val string_of_id : id -> string

module Set : (module type of BatPSet)
module Map : (module type of BatPMap)

(** {1 Title manipulation} *)

val string_of_title : title -> string
val namespace_of_title : title -> namespace

(** {1 Various stuff} *)

val parse_timestamp : string -> timestamp

val print_timestamp : timestamp -> string
