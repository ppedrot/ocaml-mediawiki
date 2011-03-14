(***********************************************************************)
(*                                                                     *)
(*                         The CamlZip library                         *)
(*                                                                     *)
(*            Xavier Leroy, projet Cristal, INRIA Rocquencourt         *)
(*                                                                     *)
(*  Copyright 2001 Institut National de Recherche en Informatique et   *)
(*  en Automatique.  All rights reserved.  This file is distributed    *)
(*  under the terms of the GNU Library General Public License, with    *)
(*  the special exception on linking described in file LICENSE.        *)
(*                                                                     *)
(***********************************************************************)

(* $Id: gzip.ml,v 1.2 2006/04/04 08:29:07 xleroy Exp $ *)

(* Module [Gzip]: reading and writing to/from [gzip] compressed files *)

open Netchannels

exception Error of string

let buffer_size = 1024

(* Superficial parsing of header *)
let parse_header ic =
  begin try
    let id1 = ic#input_byte () in
    let id2 = ic#input_byte () in
    if id1 <> 0x1F || id2 <> 0x8B then 
      raise(Error("bad magic number, not a gzip file"));
    let cm = ic#input_byte () in
    if cm <> 8 then
      raise(Error("unknown compression method"));
    let flags = ic#input_byte () in
    if flags land 0xE0 <> 0 then
      raise(Error("bad flags, not a gzip file"));
    for i = 1 to 6 do ignore(ic#input_byte ()) done;
    if flags land 0x04 <> 0 then begin
      (* Skip extra data *)
      let len1 = ic#input_byte () in
      let len2 = ic#input_byte () in
      for i = 1 to len1 + len2 lsl 8 do ignore(ic#input_byte ()) done
    end;
    if flags land 0x08 <> 0 then begin
      (* Skip original file name *)
      while ic#input_byte () <> 0 do () done
    end;
    if flags land 0x10 <> 0 then begin
      (* Skip comment *)
      while ic#input_byte () <> 0 do () done
    end;
    if flags land 0x02 <> 0 then begin
      (* Skip header CRC *)
      ignore(ic#input_byte ()); ignore(ic#input_byte ())
    end
  with End_of_file ->
    raise(Error("premature end of file, not a gzip file"))
  end

let input_inflate ic : in_obj_channel =
  object (self)

    initializer parse_header ic

    val in_chan : in_obj_channel = ic
    val in_buffer = String.create buffer_size
    val char_buffer = String.create 1
    val line_buffer = Buffer.create buffer_size
    val mutable in_abs_pos = 0
    val mutable in_pos = 0
    val mutable in_avail = 0
    val mutable in_eof = false
    val in_stream = Zlib.inflate_init false
    val mutable in_size = 0l
    val mutable in_crc = 0l

    method private read_byte () =
      if in_avail = 0 then self#refill ();
      let c = in_buffer.[in_pos] in
      in_pos <- in_pos + 1;
      in_abs_pos <- in_abs_pos + 1;
      in_avail <- in_avail - 1;
      Char.code c

    method private refill () =
      let n = in_chan#input in_buffer 0 buffer_size in
      if n = 0 then raise End_of_file;
      in_pos <- 0;
      in_avail <- n

    method private read_int32 () =
      let b1 = self#read_byte () in
      let b2 = self#read_byte () in
      let b3 = self#read_byte () in
      let b4 = self#read_byte () in
      Int32.logor (Int32.of_int b1)
        (Int32.logor (Int32.shift_left (Int32.of_int b2) 8)
          (Int32.logor (Int32.shift_left (Int32.of_int b3) 16)
                      (Int32.shift_left (Int32.of_int b4) 24)))

    method close_in () =
      in_eof <- true;
      Zlib.inflate_end in_stream;
      in_chan#close_in ()

    method input buf pos len =
      if pos < 0 || len < 0 || pos + len > String.length buf then
        invalid_arg "Gzip.input";
      if in_eof then raise End_of_file
      else begin
        if in_avail = 0 then self#refill ();
        let (finished, used_in, used_out) =
          try
            Zlib.inflate in_stream in_buffer in_pos in_avail
                                      buf pos len Zlib.Z_SYNC_FLUSH
          with Zlib.Error(_, _) ->
            raise(Error("error during decompression")) in
        in_pos <- in_pos + used_in;
        in_avail <- in_avail - used_in;
        in_crc <- Zlib.update_crc in_crc buf pos used_out;
        in_size <- Int32.add in_size (Int32.of_int used_out);
        in_abs_pos <- in_abs_pos + used_out;
        if finished then begin
          try
            let crc = self#read_int32 () in
            let size = self#read_int32 () in
            if in_crc <> crc then 
              raise(Error("CRC mismatch, data corrupted"));
            if in_size <> size then
              raise(Error("size mismatch, data corrupted"));
            in_eof <- true;
            used_out
          with End_of_file ->
            raise(Error("truncated file"))
        end
        else if used_out = 0 then
          self#input buf pos len
        else
          used_out
      end

    method really_input buf pos len =
      if len <= 0 then () else begin
        let n = self#input buf pos len in
        if n = 0 then raise End_of_file;
        self#really_input buf (pos + n) (len - n)
      end

    method input_char () =
      if self#input char_buffer 0 1 = 0 then
        raise End_of_file
      else char_buffer.[0]

    method input_byte () =
      Char.code (self#input_char ())

    method input_line () =
      let off = self#input char_buffer 0 1 in
      let c = char_buffer.[0] in
      if off = 0 || (off = 1 && c = '\n') then
        let str = Buffer.contents line_buffer in
        let () = Buffer.reset line_buffer in str
      else
        let () = Buffer.add_char line_buffer c in
        self#input_line ()

    method pos_in = in_abs_pos

  end
