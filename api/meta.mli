open Utils
open Datatypes

val namespaces : session -> namespace_info list Call.t
(** [namespaces s] return the list of all namespaces from the site. *)
