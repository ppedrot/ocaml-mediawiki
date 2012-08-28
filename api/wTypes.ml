(** Basic datatypes of Mediawiki *)

type namespace = int
type timestamp = Netdate.t

type page_t = [ `PAGE ]
type category_t = [ `PAGE | `CATEGORY ]
type revision_t = [ `REVISION ]
type user_t = [ `USER ]
type rc_t

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

module Timestamp =
struct

open Netdate

type t = Netdate.t

(* Parse an internet timestamp as yyyy-mm-ddThh:mm:ssZ *)
let of_string ts =
  let parse year month day hour minute second =
    { year = year;
    month = month;
    day = day;
    hour = hour;
    minute = minute;
    second = second;
    nanos = 0;
    zone = 0;
    week_day = -1; }
  in
  Scanf.sscanf ts "%4i-%2i-%2iT%2i:%2i:%2iZ" parse

let to_string ts =
  Printf.sprintf "%04i-%02i-%02iT%02i:%02i:%02iZ"
  ts.year ts.month ts.day ts.hour ts.minute ts.second

end
