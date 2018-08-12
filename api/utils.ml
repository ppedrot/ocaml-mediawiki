open Printf
open Datatypes

type mw_version = {
  mw_major : int;
  mw_minor : int;
}

let user_agent = "ocaml-mediawiki"

module Set = BatSet.PSet
module Map = BatMap

