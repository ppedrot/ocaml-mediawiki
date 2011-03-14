open Datatypes

(** {1 Backlinks} *)

val backlinks : session ->
  ?ns:namespace -> ?rdrfilter:redirect_filter -> ?rdr:bool ->
  title -> title list Call.t

(** {1 Embedded pages} *)

val embeddedin : session ->
  ?ns:namespace -> ?rdrfilter:redirect_filter ->
  title -> title list Call.t
