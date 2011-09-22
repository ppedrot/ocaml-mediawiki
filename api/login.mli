(** {5 Login functions} *)

open Datatypes

val login : site -> string -> string -> session
(** Login with a username and a password. *)

val anonymous_login : site -> session
(** Create an anonymous session. *)

val relogin : site -> string -> session
(** Login with session data obtained through {!Datatypes.session.save} *)
