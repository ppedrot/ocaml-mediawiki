open Datatypes

type mw_version = { mw_major : int; mw_minor : int; }

val user_agent : string

(** {1 Identifiers} *)

val id_of_string : string -> id
val string_of_id : id -> string

module SetID : (Set.S with type elt = id)
module MapID : (Map.S with type key = id)

(** {1 Title manipulation} *)

val string_of_title : title -> string
val namespace_of_title : title -> namespace

(** {1 Various stuff} *)

module MapString : (Map.S with type key = string)

val parse_timestamp : string -> timestamp

val print_timestamp : timestamp -> string
