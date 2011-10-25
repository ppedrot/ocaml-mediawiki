(* Create a multipart/form-data message out of:

  1. A list of key/value pairs.
  2. The name of the file to be transmitted, with key "file".

*)
val multipart_mime_message : (string * string option) list -> string ->
  Netmime.mime_header * Netmime.mime_body
