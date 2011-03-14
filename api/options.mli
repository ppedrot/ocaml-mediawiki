open Datatypes

(** Translation from options to queries *)

(* val arg_namespace : string -> namespace option -> query *)

val arg_namespaces : string -> namespace list -> query

val arg_minor_flag : minor_flag -> query

val arg_watch_flag : watch_flag -> query

val arg_create_flag : create_flag -> query

val arg_redirect_filter : string -> redirect_filter -> query

val arg_bool : string -> bool -> query
