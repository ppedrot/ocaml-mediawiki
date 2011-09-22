(** {5 Miscellaneous queries} *)

open Datatypes

val random : session -> ?ns:namespace list -> ?rdr:bool ->
  unit -> title Call.t
(** Choose a random page. *)

val purge : session -> title list -> unit Call.t
(** Purges a list of pages. *)

val emailuser : session -> ?subject:string -> ?text:string ->
  ?ccme:bool -> user -> unit Call.t
(** Write an email to a given user. *)

val watch : session -> title -> unit Call.t
(** Put a page on your watchlist. *)

val unwatch : session -> title -> unit Call.t
(** Remove a page from your watchlist. *)
