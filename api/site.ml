open Printf
open Http_client
open Utils
open Datatypes

let wikisource lang = {
  site_name = "wikisource";
  site_api = sprintf "http://%s.wikisource.org/w/api.php?format=xml" lang;
  site_lang = lang;
}
