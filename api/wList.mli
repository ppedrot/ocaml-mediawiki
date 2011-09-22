(** {5 List queries} *)

open Datatypes

(** {6 Random page} *)

val random : session -> ?ns:namespace list -> ?rdr:bool ->
  unit -> title Call.t

(** {6 Backlinks} *)

val backlinks : session ->
  ?ns:namespace list -> ?rdrfilter:redirect_filter -> ?rdr:bool ->
  ?limit:int -> title -> title Enum.t

(** {6 Embedded pages} *)

val embeddedin : session ->
  ?ns:namespace list -> ?rdrfilter:redirect_filter ->
  ?limit:int -> title -> title Enum.t

(** {6 Image usage} *)

val imageusage : session ->
  ?ns:namespace list -> ?rdrfilter:redirect_filter -> ?rdr:bool ->
  ?limit:int -> title -> title Enum.t

(** {6 Search} *)

val search : session ->
  ?ns:namespace list -> ?what:search_type -> ?rdr:bool ->
  ?limit:int -> string -> title Enum.t

(* TODO *)

(*
  allimages
  allpages
  alllinks
  allcategories
  allusers
  blocks
  categorymembers
  deletedrevs
  logevents
  recentchanges
  tags
  usercontribs
  watchlist
  watchlistraw
  exturlusage
  users
  protectedtitles
*)
