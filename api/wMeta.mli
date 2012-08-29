(** {5 Meta-information queries} *)

open Datatypes

val general_info : session -> (string * string) list Call.t
(** Get information about the site as (key, value) pairs . *)

val namespaces : session -> namespace_info list Call.t
(** Get the list of all namespaces from the site. *)

val statistics : session -> site_statistics Call.t
(** Get the statistics of the site. *)

val interwikis : session -> interwiki_info list Call.t
(** Get info about the interwikis. *)

val user_info : session -> user_info Call.t
(** Retrieve information about the current user. *)
