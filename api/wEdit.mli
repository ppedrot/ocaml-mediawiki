(** {5 Write queries}*)

open Datatypes

(** {6 Writing pages} *)

val write_page : session -> ?summary:string -> ?minor:minor_flag ->
  ?watch:watch_flag -> ?bot:bool -> ?create:create_flag ->
  page -> string -> edit_status Call.t
(** Write a given page and return the status. This function checks that there
    is no conflict thanks to the last timestamp of the page.

  @param summary Reason of the move. Default: [""]
  @param minor Set the minor flag. Default: [`DEFAULT]
  @param watch Add the page to your watchlist. Default: [`DEFAULT]
  @param bot Set the bot flag. Default: [false]
  @param create Behaviour w.r.t. the existing status. Default: [`DEFAULT]
*)

val write_title : session -> ?summary:string -> ?minor:minor_flag ->
  ?watch:watch_flag -> ?bot:bool -> ?create:create_flag ->
  title -> string -> edit_status Call.t
(** As for {!write_page} but with a title only. Do not check for any conflict. *)

(** {6 Moving pages} *)

val move_page : session -> ?summary:string -> ?watch:watch_flag -> ?rdr:bool -> 
  ?move_subpages:bool -> ?move_talk:bool -> ?ignore_warnings:bool ->
  page -> title -> move_status Call.t
(** Move a page to a given title.

  @param summary Reason of the move. Default: [""]
  @param watch Add the page to your watchlist. Default: [`DEFAULT]
  @param rdr Create the redirect. Default: [true]
  @param move_subpages Also move the subpages. Default: [true]
  @param move_talk Also move the talk page. Default: [true]
  @param ignore_warnings Ignore any warnings. Default: [false]
*)