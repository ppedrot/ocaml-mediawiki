(** {5 General utility functions.} *)

open WTypes
open Datatypes

type mw_version = { mw_major : int; mw_minor : int; }

val user_agent : string

(** {6 Identifiers} *)

module Set : (module type of BatSet.PSet)
module Map : (module type of BatMap)
