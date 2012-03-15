open Printf
open Http_client
open Utils
open Datatypes

let create name url lang = {
  site_name = name;
  site_api = sprintf "%s" url;
  site_lang = lang;
}

let wikipedia lang = {
  site_name = "wikipedia";
  site_api = sprintf "https://%s.wikipedia.org/w/api.php" lang;
  site_lang = lang;
}

let wikisource lang = {
  site_name = "wikisource";
  site_api = sprintf "https://%s.wikisource.org/w/api.php" lang;
  site_lang = lang;
}

let wikicommons = {
  site_name = "commons";
  site_api = "https://secure.wikimedia.org/wikipedia/commons/w/api.php";
  site_lang = "";
}
