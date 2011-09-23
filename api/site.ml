open Printf
open Http_client
open Utils
open Datatypes

let create name url lang = {
  site_name = name;
  site_api = sprintf "%s?format=xml" url;
  site_lang = lang;
}

let wikisource lang = {
  site_name = "wikisource";
  site_api = sprintf "http://%s.wikisource.org/w/api.php?format=xml" lang;
  site_lang = lang;
}

let wikicommons = {
  site_name = "commons";
  site_api = "http://commons.wikimedia.org/w/api.php?format=xml";
  site_lang = "";
}
