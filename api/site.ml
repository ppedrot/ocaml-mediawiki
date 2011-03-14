open Printf
open Http_client
open Utils
open Datatypes

let encode s = Netencoding.Url.encode ~plus:false s

let fr_wikisource : site =
  object (self)

    val mutable session = None

    method name = "wikisource"

    method query q =
      let api = "http://fr.wikisource.org/w/api.php?format=xml" in
      let map = function
      | (v, None) -> sprintf "&%s" (encode v)
      | (v, Some arg) -> sprintf "&%s=%s" (encode v) (encode arg)
      in
      String.concat "" (api :: List.map map q)

    method session = session

    method clear_session () = session <- None

    method set_session s = session <- Some s

  end
