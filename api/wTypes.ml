module Id =
struct

type 'a t = Int64.t

let cast x = x

let of_string s = Int64.of_string s

let to_string id = Int64.to_string id

end

module Title =
struct

type t = {
  path : string;
  namespace : int;
}

let make path ns = {
  path = path;
  namespace = ns;
}

let to_string t = t.path

let namespace t = t.namespace

end
