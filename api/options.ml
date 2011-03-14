open Datatypes

(* Translation from arguments to strings *)

let default opt def = match opt with
| None -> def
| Some x -> x

let arg_namespace opt = match opt with
| None -> []
| Some ns -> ["namespace", Some (string_of_int ns)]

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

let arg_bool tag b = if b then ["tag", None] else []
