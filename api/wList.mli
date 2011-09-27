(**
  {5 List queries}

  These queries return various (usually huge) lists, presented as enumerations.
*)

open Datatypes

val allpages : session ->
  ?ns:namespace -> ?from:string -> ?upto:string -> ?prefix:string ->
  ?rdrfilter:redirect_filter -> ?minsize:int -> ?maxsize:int -> ?order:order -> 
  ?limit:int -> unit -> title Enum.t
(** Enumerate all pages.

  @param ns The namespace to enumerate. Default: [0]
  @param from The page from which to start the enumeration. Default: none
  @param upto The page up to which do the enumeration. Default: none
  @param prefix Only enumerate pages that starts with this prefix. Default: empty
  @param rdrfilter Enumerate redirects. Default: [`ALL]
  @param minsize Minimum size in bytes of page to be enumerated. Default: none
  @param maxsize Maximum size in bytes of page to be enumerated. Default: none
  @param order Order of the enumeration. Default: [`INCR]
  @param limit Maximum number of pages to enumerate. Default: [max_int]
*)

val allcategories : session ->
  ?from:string -> ?upto:string -> ?prefix:string -> ?order:order -> 
  ?limit:int -> unit -> category_info Enum.t
(** Enumerate all pages.

  @param from The category from which to start the enumeration. Default: none
  @param upto The category up to which do the enumeration. Default: none
  @param prefix Only enumerate category that starts with this prefix. Default: empty
  @param order Order of the enumeration. Default: [`INCR]
  @param limit Maximum number of pages to enumerate. Default: [max_int]
*)

val backlinks : session ->
  ?ns:namespace list -> ?rdrfilter:redirect_filter -> ?rdr:bool ->
  ?limit:int -> title -> title Enum.t
(** Enumerate all pages linking to the given page.

  @param ns Namespaces to enumerate. Default: all
  @param rdrfilter Enumerate redirects. Default: [`ALL]
  @param rdr Recursively enumerate pages which are redirects. Default: [false]
  @param limit Maximum number of pages to enumerate. Default: [max_int]
*)

val embeddedin : session ->
  ?ns:namespace list -> ?rdrfilter:redirect_filter ->
  ?limit:int -> title -> title Enum.t
(** Enumerate all pages embedded in the given page.

  @param ns Namespaces to enumerate. Default: all
  @param rdrfilter Enumerate redirects. Default: [`ALL]
  @param limit Maximum number of pages to enumerate. Default: [max_int]
*)

val exturlusage : session ->
  ?ns:namespace list -> ?limit:int -> string -> (title * string) Enum.t
(** Enumerate all pages using a given URL pattern.

  @param ns Namespaces to enumerate. Default: all
  @param limit Maximum number of pages to enumerate. Default: [max_int]
*)

val imageusage : session ->
  ?ns:namespace list -> ?rdrfilter:redirect_filter -> ?rdr:bool ->
  ?limit:int -> title -> title Enum.t
(** Enumerate all pages that use the given page.

  @param ns Namespaces to enumerate. Default: all
  @param rdrfilter Enumerate redirects. Default: [`ALL]
  @param rdr Recursively enumerate pages which are redirects. Default: [false]
  @param limit Maximum number of pages to enumerate. Default: [max_int]
*)

val recentchanges : session ->
  ?fromts:timestamp -> ?uptots:timestamp -> ?ns:namespace list -> 
  ?order:order -> ?usrfilter:user_filter -> ?limit:int -> 
  unit -> rc_info Enum.t
(** List all recent changes.

  @param fromts Timestamp to enumerate from. Default: none
  @param uptots Timestamp to enumerate up to. Default: none
  @param ns Namespaces to enumerate. Default: all
  @param order Order of the enumeration. Default: [`DECR]
  @param usrfilter Display or exclude a particular user. Default: [`ALL]
  @param limit Maximum number of pages to enumerate. Default: [max_int]  
*)


val search : session ->
  ?ns:namespace list -> ?what:search_type -> ?rdr:bool ->
  ?limit:int -> string -> title Enum.t
(** Search for a given string on a Mediawiki site.

  @param ns Namespaces to enumerate. Default: all
  @param what Search inside the text or titles. Default: [`TEXT]
  @param rdr Include redirects. Default: [false]
  @param limit Maximum number of pages to enumerate. Default: [max_int]
*)

(* TODO *)

(*
  allimages
  alllinks
  allusers
  blocks
  categorymembers
  deletedrevs
  logevents
  tags
  usercontribs
  watchlist
  watchlistraw
  users
  protectedtitles
*)
