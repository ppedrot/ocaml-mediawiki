open Netmime

let multipart_mime_message fields file : (mime_header * mime_body) =
  (* Create a multipart message *)
  let file_body : mime_body = new file_mime_body file in
  let file_header = new basic_mime_header [
    "Content-Disposition", "form-data; name=\"file\"";
    "Content-Type", "application/octet-stream";
    "Content-transfer-encoding", "base64";
  ] in
  let make_part (name, value) =
    let header = new basic_mime_header [
      "Content-Disposition", "form-data; name=\"" ^ name ^ "\"";
      "Content-Type", "text/plain; charset=UTF-8";
      "Content-Transfer-Encoding", "base64";
    ] in
    let body = match value with
    | None -> new memory_mime_body ""
    | Some str -> new memory_mime_body str
    in
    (header, `Body (body :> mime_body))
  in
  let boundary = Mimestring.create_boundary () in
  let multipart_body = (List.map make_part fields) @ [file_header, `Body file_body] in
  let multipart_header = new basic_mime_header [
    "Content-Type", "multipart/form-data; boundary=\"" ^ boundary ^ "\"";
    "Content-Transfer-Encoding", "7bit";
  ] in
  (* Flatten the multipart *)
  let message = (multipart_header, `Parts multipart_body) in
  let (tmp_file, tmp_in, tmp_out) = Netchannels.make_temporary_file () in
  let () = close_in tmp_in in
  let tmp_out = new Netchannels.output_channel tmp_out in
  let () = write_mime_message ~wr_header:false tmp_out message in
  let () = tmp_out#close_out () in
  let multipart_body = new file_mime_body ~fin:true tmp_file in
  (multipart_header, multipart_body)
