module Id :
  sig
    type +'a t = private Int64.t
    val cast : Int64.t -> 'a t
    val of_string : string -> 'a t
    val to_string : 'a t -> string
  end

class type identified =
  object ('self)
    method id : 'self Id.t
  end
