open Datatypes

type login

val get_login : string -> string -> login

val login : site -> login -> session
(** Login with a username and a password. *)

val anonymous_login : site -> session
(** Create an anonymous session. *)

val relogin : site -> string -> session
(** Login with session data obtained through [save] *)
