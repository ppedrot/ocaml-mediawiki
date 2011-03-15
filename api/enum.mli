open Datatypes

(** {1 Random page} *)

val random : session -> ?ns:namespace list -> ?rdr:bool ->
  unit -> title Call.t

(** {1 Backlinks} *)

val backlinks : session ->
  ?ns:namespace list -> ?rdrfilter:redirect_filter -> ?rdr:bool ->
  title -> title list Call.t

(** {1 Embedded pages} *)

val embeddedin : session ->
  ?ns:namespace list -> ?rdrfilter:redirect_filter ->
  title -> title list Call.t

(** {1 Image usage} *)

val imageusage : session ->
  ?ns:namespace list -> ?rdrfilter:redirect_filter -> ?rdr:bool ->
  title -> title list Call.t

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
  search
  tags
  usercontribs
  watchlist
  watchlistraw
  exturlusage
  users
  protectedtitles
*)
