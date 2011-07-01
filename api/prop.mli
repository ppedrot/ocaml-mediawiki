open Utils
open Datatypes

(** {1 Page retrieving} *)

val of_titles : session -> string list -> page_result MapString.t Call.t
(** [of_titles s titles] associates to every title in [titles] the corresponding
    page. If the title is invalid, associates [Invalid]. If the page is missing,
    associates [Missing t] where [t] is the normalized form of the title. *)

val of_pageids : session -> id list -> page_result MapID.t Call.t
(** [of_pageids s pageids] associates to every page id in [pageids] the 
    corresponding page. If the id is invalid or missing, returns [Invalid]. *)

(** {1 Revision retrieving} *)

val revisions : session -> ?fromid:id -> ?uptoid:id -> ?fromts:timestamp ->
  ?uptots:timestamp -> ?usrfilter:user_filter -> page -> revision list Call.t
(** Returns the list of revisions of a given page. 
    Empty result if the page is invalid. *)

val of_revids : session -> id list -> revision MapID.t Call.t
(** [of_revids s revids] associates to every revision id in [revids] the 
    corresponding revision. If the id is invalid or missing, it is absent from
    the answer. *)

(** {1 Content} *)

val content : session -> revision list -> string MapID.t Call.t
(** Associates to every revision its content by id.
    If a revision is invalid, it is not present in the answer. *)

(** {1 Diffs} *)

val diff : session -> id -> relative_id -> diff Call.t

(** {1 Links} *)

val links : session -> ?ns:namespace list -> page -> title list Call.t
(** Returns the list of link titles from a given page. *)

(** {1 Language links} *)

val langlinks : session -> page -> langlink list Call.t
(** Return the list of interwiki links from a given page. *)

(** {1 Images} *)

val images : session -> page -> title list Call.t
(** Returns the list of image titles used on a given page. *)

(** {1 Templates} *)

val templates : session -> ?ns:namespace list -> page -> title list Call.t
(** Returns the list of template titles used on a given page. *)

(** {1 Categories} *)

val categories : session -> page -> string list Call.t
(** Returns the list of categories to which pertains a given page. *)

(** {1 External links} *)

val external_links : session -> page -> string list Call.t

(** {1 Debugging} *)

val dummy_title : title
val dummy_page : id -> page
val dummy_revision : id -> revision
