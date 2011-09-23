(**
  {5 List queries}

  These queries are returning various lists.
*)

open Datatypes

val allpages : session ->
  ?ns:namespace -> ?from:string -> ?upto:string -> ?prefix:string ->
  ?rdrfilter:redirect_filter -> ?minsize:int -> ?maxsize:int -> ?order:order -> 
  ?limit:int -> unit -> title Enum.t
(** Enumerate all pages. *)

val backlinks : session ->
  ?ns:namespace list -> ?rdrfilter:redirect_filter -> ?rdr:bool ->
  ?limit:int -> title -> title Enum.t
(** Enumerate all pages linking to the given page. *)

val embeddedin : session ->
  ?ns:namespace list -> ?rdrfilter:redirect_filter ->
  ?limit:int -> title -> title Enum.t
(** Enumerate all pages embedded in the given page. *)

val imageusage : session ->
  ?ns:namespace list -> ?rdrfilter:redirect_filter -> ?rdr:bool ->
  ?limit:int -> title -> title Enum.t
(** Enumerate all pages that use the given page. *)

val search : session ->
  ?ns:namespace list -> ?what:search_type -> ?rdr:bool ->
  ?limit:int -> string -> title Enum.t
(** Search for a given string on a Mediawiki site. *)

(* TODO *)

(*
  allimages
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
