(** Basic datatypes of Mediawiki *)

module Id :
  sig
    type +'a t = private Int64.t
    val cast : Int64.t -> 'a t
    val of_string : string -> 'a t
    val to_string : 'a t -> string
  end

module Title :
  sig
    type t
    val make : ?raw:string -> string -> int -> t
    (** [make base norm ns] create a title its a raw title, its normalized one 
        and its namespace. *)
    val to_string : t -> string
    val namespace : t -> int
  end
