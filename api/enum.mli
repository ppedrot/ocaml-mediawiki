open Datatypes

(** {1 Random page} *)

val random : session -> ?ns:namespace list -> ?rdr:bool ->
  unit -> title Call.t

(** {1 Backlinks} *)

val backlinks : session ->
  ?ns:namespace list -> ?rdrfilter:redirect_filter -> ?rdr:bool ->
  title -> title list Call.t

(** {1 Embedded pages} *)

val embeddedin : session ->
  ?ns:namespace list -> ?rdrfilter:redirect_filter ->
  title -> title list Call.t
