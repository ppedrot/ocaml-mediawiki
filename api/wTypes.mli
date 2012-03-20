(** {5 Basic datatypes of Mediawiki} *)

type namespace = int

(** {6 Phantom types} *)

type page_t
type revision_t

(** {6 Core types} *)

module Id :
  sig
    (** {5 Identifiers} *)

    type +'a t = private Int64.t
    (** Identifiers use phantom types to ensure safety *)

    val cast : Int64.t -> 'a t
    val of_string : string -> 'a t
    val to_string : 'a t -> string
  end

module Title :
  sig
    (** {5 Titles} *)

    type t
    val make : string -> namespace -> t
    (** Creates a title from a normalized title and a
        namespace. *)
    val to_string : t -> string
    (** Returns the normalized form of the title *)
    val namespace : t -> namespace
    (** Returns the namespace to which belongs the titlte *)
  end

module Timestamp :
  sig
    (** {5 Timestamps} *)

    type t
    val of_string : string -> t
    (** Parses a timestamp as [yyyy-mm-ddThh:mm:ssZ] *)
    val to_string : t -> string
    (** Prints a timestamp according to the previous pattern *)
  end
