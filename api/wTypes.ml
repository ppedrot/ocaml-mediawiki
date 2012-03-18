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
  normalized : string;
  namespace : int;
}

let make ?raw normalized ns = {
  path = (match raw with None -> normalized | Some path -> path);
  normalized = normalized;
  namespace = ns;
}

let to_string t = t.normalized

let namespace t = t.namespace

end

class type identified =
  object ('self)
    method id : 'self Id.t
  end
