(** {5 Mediawiki site manipulation} *)

open Datatypes

val create : string -> string -> string -> site
(** [create name url lang] creates a mediawiki site where [name] is the name of 
  the wiki, [url] is the URL of the API and [lang] is the ISO code of the 
  language of the wiki.
*)

val wikisource : string -> site
(** Create a Wikisource site from a given language. *)

val wikicommons : site
(** Wikimedia Commons. *)
