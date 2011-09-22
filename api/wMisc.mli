open Datatypes

(** {1 Miscellaneous queries} *)

val purge : session -> title list -> unit Call.t

val emailuser : session -> ?subject:string -> ?text:string ->
  ?ccme:bool -> user -> unit Call.t

val watch : session -> title -> unit Call.t

val unwatch : session -> title -> unit Call.t
