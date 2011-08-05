open Datatypes

val namespaces : session -> namespace_info list Call.t
(** Returns the list of all namespaces from the site. *)

val userinfo : session -> user_info Call.t
(** Retrieve information about the current user. *)
