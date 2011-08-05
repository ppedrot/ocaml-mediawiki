(*
  Extracting text out of proofread pages.
  Reference code from MediaWiki ProofRead extension at:
  http://svn.wikimedia.org/viewvc/mediawiki/trunk/extensions/ProofreadPage/proofread.js
*)

type proofread_page = {
  pr_head : string;
  pr_text : string;
  pr_foot : string;
  pr_level : int;
  pr_user : string;
}

let re1 = "^<noinclude>([\\s\\S]*?)\n*<\\/noinclude>([\\s\\S]*)<noinclude>([\\s\\S]*?)<\\/noinclude>\n$"
let re2 = "^<noinclude>([\\s\\S]*?)\n*<\\/noinclude>([\\s\\S]*?)\n$"
let re3 = "^([\\s\\S]*?)<noinclude>([\\s\\S]*?)<\\/noinclude>"
let re4 = "<pagequality level=\"(\\d)\" user=\"(.*?)\"\\/>"
let re5 = "\\{\\{PageQuality\\|(\\d)(\\|(.*?|))\\}\\}"

let re1 = Pcre.regexp ~flags:[`UTF8] re1
let re2 = Pcre.regexp ~flags:[`UTF8] re2
let re3 = Pcre.regexp ~flags:[`UTF8] re3
let re4 = Pcre.regexp ~flags:[`UTF8] re4
let re5 = Pcre.regexp ~flags:[`UTF8] re5

(* Decompose the source into header, body and footer. *)
let parse s =
  try
    let ans = Pcre.extract ~rex:re1 ~full_match:false s in
    (ans.(0), ans.(1), ans.(2))
  with Not_found ->
    try
      let ans = Pcre.extract ~rex:re2 ~full_match: false s in
      let head = ans.(0) in
      let body = ans.(1) in
      try
        let matched = Pcre.extract ~rex:re3 ~full_match:false body in
        (head, matched.(0), matched.(1))
      with Not_found -> (head, body, "")
    with Not_found -> ("", s, "")

(* Retrieve the quality information *)
let get_quality hd =
  try
    let ans = Pcre.extract ~rex:re4 ~full_match:false hd in
    Some (int_of_string ans.(0), ans.(1))
  with Not_found ->
    try
      let ans = Pcre.extract ~rex:re5 ~full_match:false hd in
      Some (int_of_string ans.(0), ans.(1))
    with Not_found -> None
