(** {5 General utility functions.} *)

open Datatypes

type mw_version = { mw_major : int; mw_minor : int; }

val user_agent : string

(** {6 Identifiers} *)

module Set : (module type of BatPSet)
module Map : (module type of BatPMap)

(** {6 Various stuff} *)

val parse_timestamp : string -> timestamp

val print_timestamp : timestamp -> string
