#!/usr/bin/ocaml

(**

  A script to retrieve a given file from Gallica in high resolution, instead of
  low-res samples. Uses the zoom tool to get 1024x1024 subpictures of the 
  document and glues them together to create the final document.

  Requires: wget and imagemagick toolkit.

  First argument: ark of the document.
  Second (optional) argument: page to retrieve, default: first one.

  Example:

  ./gallica.ml btv1b23000047 2

*)

open Printf

let file =
  if Array.length Sys.argv > 1 then
    Sys.argv.(1)
  else (eprintf "No argument given.\n"; exit 1)

let page = try int_of_string Sys.argv.(2) with _ -> 1

let wget_address i j =
  sprintf "http://gallica.bnf.fr/proxy?method=R&ark=%s.f%i&l=7&r=%i,%i,1024,1024"
  file page (j * 1024) (i * 1024)

let retrieve () =
  let x = ref 0 in
  let y = ref 0 in
  let break_x = ref true in
  let break_y = ref true in
  let max_x = ref (-1) in
  let max_y = ref (-1) in
  while !break_y do
    let test = ref false in
    let () = x := 0 in
    let () = break_x := true in
    while !break_x do
      let address = wget_address !x !y in
      let name = sprintf "%s-%02i-%02i.jpg" file !x !y in
      let command = sprintf "wget -U wikisource --quiet \"%s\" -O %s" address name in
      let ret = Sys.command command in
      if ret <> 0 then
        begin Sys.remove name; break_x := false end
      else
        begin
          max_x := max !x !max_x;
          printf "Downloaded %02i-%02i...\n%!" !x !y;
          incr x;
          test := true;
        end
    done;
    if !test then
      begin max_y := max !y !max_y; incr y end
    else
      begin break_y := false end
  done;
  (!max_x, !max_y)

let append x y =
  printf "Appending files...\n%!";
  for j = 0 to y do
    let rec gen accu n =
      if n < 0 then accu
      else gen (sprintf "%s-%02i-%02i.jpg" file n j :: accu) (pred n)
    in
    let imgs = gen [] x in
    let cimg = String.concat " " imgs in
    let command = sprintf "convert %s +append %s-xx-%02i.jpg" cimg file j in
    if Sys.command command = 0 then List.iter Sys.remove imgs else exit 1
  done;
  let rec gen accu n =
    if n < 0 then accu
    else gen (sprintf "%s-xx-%02i.jpg" file n :: accu) (pred n)
  in
  let imgs = gen [] y in
  let cimg = String.concat " " imgs in
  let command = sprintf "convert %s -append %s.jpg" cimg file in
  let ans = Sys.command command in
  if ans = 0
    then List.iter Sys.remove imgs
    else exit 1;
  printf "Finished!\n%!";
  exit 0

let _ =
  let (x, y) = retrieve () in
  if (0 <= x && 0 <= y) then append x y
  else (eprintf "Error: Missing pictures!\n"; exit 1)
