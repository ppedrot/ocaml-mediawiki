(** {5 Write queries}*)

open Datatypes

(** {6 Writing pages} *)

val write_page : session -> string -> ?summary:string -> ?minor:minor_flag ->
  ?watch:watch_flag -> ?bot:bool -> ?create:create_flag ->
  page -> edit_status Call.t
(** Writes a given page and return the status. This function checks that there
    is no conflict thanks to the last timestamp of the page. *)

val write_title : session -> string -> ?summary:string -> ?minor:minor_flag ->
  ?watch:watch_flag -> ?bot:bool -> ?create:create_flag ->
  title -> edit_status Call.t
(** As for {!write_page} but with a title only. Do not check for any conflict. *)

(** {6 Moving pages} *)

val move : session -> page -> ?summary:string -> ?watch:watch_flag ->
  ?rdr:bool -> ?move_subpages:bool -> ?move_talk:bool -> ?ignore_warnings:bool ->
  title -> unit Call.t
(** Move a page. *)