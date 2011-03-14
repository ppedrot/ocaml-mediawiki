open Datatypes

(** {1 Backlinks} *)

val backlinks : session ->
  ?ns:namespace -> ?rdrfilter:redirect_filter -> ?rdr:bool ->
  title -> title list Call.t
