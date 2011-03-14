open Datatypes

val write_page : session -> string -> ?summary:string -> ?minor:minor_flag ->
  ?watch:watch_flag -> ?bot:bool -> ?create:create_flag ->
  page -> edit_status Call.t

val write_title : session -> string -> ?summary:string -> ?minor:minor_flag ->
  ?watch:watch_flag -> ?bot:bool -> ?create:create_flag ->
  title -> edit_status Call.t
