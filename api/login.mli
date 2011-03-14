open Datatypes

type login

val get_login : string -> string -> login

val login : site -> login -> session

val anonymous_login : site -> session
