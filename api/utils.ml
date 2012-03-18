open Printf
open Datatypes

type mw_version = {
  mw_major : int;
  mw_minor : int;
}

let user_agent = "ocaml-mediawiki"

module Set = BatPSet
module Map = BatPMap

open Netdate

(* Parse an internet timestamp as yyyy-mm-ddThh:mm:ssZ *)
let parse_timestamp ts = Scanf.sscanf ts "%4i-%2i-%2iT%2i:%2i:%2iZ"
  (fun year month day hour minute second ->
  { year = year;
    month = month;
    day = day;
    hour = hour;
    minute = minute;
    second = second;
    nanos = 0;
    zone = 0;
    week_day = -1; })

let print_timestamp ts =
  Printf.sprintf "%04i-%02i-%02iT%02i:%02i:%02iZ"
  ts.year ts.month ts.day ts.hour ts.minute ts.second
