open Datatypes
open Utils

(* Translation from arguments to strings *)

let default opt def = match opt with
| None -> def
| Some x -> x

let may f = function
| None -> None
| Some x -> Some (f x)

let arg_title tag title =
  [tag ^ "title", Some (string_of_title title)]

let arg_limit tag len =
  if len < 0 then invalid_arg "arg_limit"
  else
    [tag ^ "limit", Some (string_of_int len)]

let arg_namespace tag opt = match opt with
| None -> []
| Some ns -> [tag ^ "namespace", Some (string_of_int ns)]

let arg_namespaces tag = function
| [] -> []
| l ->
  let ns = List.map string_of_int l in
  [tag ^ "namespace", Some (String.concat "|" ns)]

let arg_timestamp tag = function
| None -> []
| Some ts -> [tag, Some (print_timestamp ts)]

let arg_id tag = function
| None -> []
| Some id -> [tag, Some (string_of_id id)]

let arg_minor_flag (flag : minor_flag) = match flag with
| `DEFAULT -> []
| `MINOR -> ["minor", None]
| `NOT_MINOR -> ["notminor", None]

let arg_watch_flag (flag : watch_flag) = match flag with
| `DEFAULT -> ["watchlist", Some "preferences"]
| `NO_CHANGE -> ["watchlist", Some "nochange"]
| `UNWATCH -> ["watchlist", Some "unwatch"]
| `WATCH -> ["watchlist", Some "watch"]

let arg_create_flag (flag : create_flag) = match flag with
| `DEFAULT -> []
| `NO_CREATE -> ["nocreate", None]
| `CREATE_ONLY -> ["createonly", None]
| `RECREATE -> ["recreate", None]

let arg_redirect_filter tag (filter : redirect_filter) = match filter with
| `ALL -> [tag ^ "redirectfilter", Some "all"]
| `REDIRECT -> [tag ^ "redirectfilter", Some "redirects"]
| `NOT_REDIRECT -> [tag ^ "redirectfilter", Some "nonredirects"]

let arg_user_filter tag (filter : user_filter) = match filter with
| `ALL -> []
| `EXCLUDE user -> [tag ^ "excludeuser", Some user]
| `ONLY user -> [tag ^ "user", Some user]

let arg_bool tag b = if b then [tag, None] else []
