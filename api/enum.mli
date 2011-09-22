open Datatypes

(** {1 Enumeration type and functions} *)

type 'a t
(** Lazy enumeration type. *)

val iter : ('a -> unit) -> 'a t -> unit Call.t
(** Asynchronous iteration over enumerations. Iteration is made callwise, so 
  it does not wait for the whole list to be available to finish. *)

val map : ('a -> 'b) -> 'a t -> 'b t
(** Asynchronous map over enumerations. This is a lazy operation. *)

val fold : ('a -> 'b -> 'a) -> 'a -> 'b t -> 'a Call.t
(** [fold f accu enum] folds enum using [f]. This is eager: the call evaluation 
  may trigger a lot of API calls at once, hence making it quite costly. *)

(** {1 Random page} *)

val random : session -> ?ns:namespace list -> ?rdr:bool ->
  unit -> title Call.t

(** {1 Backlinks} *)

val backlinks : session ->
  ?ns:namespace list -> ?rdrfilter:redirect_filter -> ?rdr:bool ->
  ?limit:int -> title -> title t

(** {1 Embedded pages} *)

val embeddedin : session ->
  ?ns:namespace list -> ?rdrfilter:redirect_filter ->
  ?limit:int -> title -> title t

(** {1 Image usage} *)

val imageusage : session ->
  ?ns:namespace list -> ?rdrfilter:redirect_filter -> ?rdr:bool ->
  ?limit:int -> title -> title t

(** {1 Search} *)

val search : session ->
  ?ns:namespace list -> ?what:search_type -> ?rdr:bool ->
  ?limit:int -> string -> title t

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
