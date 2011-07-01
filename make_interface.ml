open Printf

let copy chan_in chan_out =
  let break = ref true in
  while !break do
    try
      let c = input_char chan_in in
      output_char chan_out c
    with _ -> break := false
  done;
  ()

let () =
  let chan_out = open_out "mediawiki.mli" in
  let l = Array.length Sys.argv in
  for i = 1 to (pred l) do
    let file = Sys.argv.(i) in
    let chan_in = open_in file in
    let file = Filename.basename file in
    let file = Filename.chop_extension file in
    let file = String.capitalize file in
    let () = Printf.fprintf chan_out "module %s : sig \n" file in
    let () = copy chan_in chan_out in
    Printf.fprintf chan_out "\nend\n"    
  done;
  close_out chan_out
