open WTypes
open Datatypes

(** Option manipulation *)

val may : ('a -> 'b) -> 'a option -> 'b option

(** Translation from options to queries *)

val arg_opt : string -> string option -> query

val arg_namespace : string -> namespace option -> query

val arg_title : string -> title -> query

val arg_limit : string -> int -> query

val arg_namespaces : string -> namespace list -> query

val arg_timestamp : string -> timestamp option -> query

val arg_id : string -> 'a Id.t option -> query

val arg_minor_flag : minor_flag -> query

val arg_watch_flag : watch_flag -> query

val arg_create_flag : create_flag -> query

val arg_redirect_filter : string -> redirect_filter -> query

val arg_redirect_filter_alt : string -> redirect_filter -> query

val arg_user_filter : string -> user_filter -> query

val arg_bool : string -> bool -> query
