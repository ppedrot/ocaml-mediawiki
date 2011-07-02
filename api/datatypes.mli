type id = int64

type query = (string * string option) list

type namespace = int

type timestamp = Netdate.t

type language = string

type user = string

type token_type = [ `EDIT | `MOVE ]

type redirect_filter = [ `ALL | `REDIRECT | `NOT_REDIRECT ]
type user_filter = [ `ALL | `EXCLUDE of user | `ONLY of user ]
type category_filter = [ `HIDDEN | `NOT_HIDDEN ]

type minor_flag = [ `DEFAULT | `MINOR | `NOT_MINOR ]
type watch_flag = [ `DEFAULT | `WATCH | `UNWATCH | `NO_CHANGE ]
type create_flag = [ `DEFAULT | `NO_CREATE | `CREATE_ONLY | `RECREATE ]

type edit_status = [ `UPDATE | `NO_CHANGE | `NEW ]
type move_status = [ `REDIRECT_CREATED ]

type relative_id = [ `ID of id | `PREVIOUS | `CURRENT | `NEXT ]

type token = {
  token : string;
  token_type : token_type;
  token_ts : timestamp;
}

type title = {
  title_path : string;
  title_namespace : namespace;
}

type page = {
  page_title : title;
  page_id : id;
  page_touched : timestamp;
  page_lastrevid : id;
  page_length : int;
  page_redirect : bool;
  page_new : bool;
}

type revision = {
  rev_id : id;
  rev_page : id;
  rev_timestamp : timestamp;
  rev_user : string;
  rev_comment : string;
  rev_minor : bool;
}

type diff = {
  diff_src : id;
  diff_dst : id;
  diff_val : string;
}

type langlink = {
  lang_title : string;
  lang_language : language;
}

type namespace_info = {
  ns_id : namespace;
  ns_name : string;
  ns_canonical : string option;
  ns_content : bool;
  ns_case_sensitive : bool;
  ns_subpages : bool;
  ns_aliases : string list;
}

type user_info = {
  user_id : id;
  user_name : string;
  user_anon : bool;
  user_groups : string list;
}

type page_result = [ `INVALID | `MISSING of title | `EXISTING of page ]

class type site =
  object
    method name : string
    method api_address : string
    method session : session option
    method set_session : session -> unit
    method clear_session : unit -> unit
  end

and session =
  object
    method site : site
    method username : string option
    method userid : id
    method is_valid : bool
    method get_call : query -> Call.call
    method post_call : query -> Call.call
    method edit_token : token
    method logout : unit -> unit
  end
