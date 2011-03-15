open Printf
open Datatypes

type id = int64

type mw_version = {
  mw_major : int;
  mw_minor : int;
}

let user_agent = "ocaml-mediawiki"

let id_of_string = Int64.of_string
let string_of_id = Int64.to_string

let string_of_title t = t.title_path
let namespace_of_title t = t.title_namespace

module OrderedId =
struct
  type t = id
  let compare = Int64.compare
end

module OrderedString =
struct
  type t = string
  let compare = String.compare
end

module MapID = Map.Make(OrderedId)
module SetID = Set.Make(OrderedId)

module MapString = Map.Make(OrderedString)

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
    zone = 0;
    week_day = -1; })

let print_timestamp ts =
  Printf.sprintf "%04i-%02i-%02iT%02i:%02i:%02iZ"
  ts.year ts.month ts.day ts.hour ts.minute ts.second
