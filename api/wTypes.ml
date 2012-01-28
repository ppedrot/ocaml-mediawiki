module Id =
struct
  type 'a t = Int64.t
  let cast x = x
  let of_string s = Int64.of_string s
  let to_string id = Int64.to_string id
end

class type identified =
  object ('self)
    method id : 'self Id.t
  end
