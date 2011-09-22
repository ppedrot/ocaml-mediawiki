(** {5 Mediawiki site manipulation} *)

open Datatypes

val wikisource : string -> site
(** Create a Wikisource site from a given language. *)

val wikicommons : site
(** Wikimedia Commons. *)
