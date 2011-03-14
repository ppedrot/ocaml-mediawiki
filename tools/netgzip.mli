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

(* $Id: gzip.mli,v 1.4 2007/01/21 15:12:55 xleroy Exp $ *)

(** Reading and writing to/from [gzip] compressed files

   This module provides functions to read and write compressed data
   to/from files in [gzip] format. *)

open Netchannels

(** {6 Reading from compressed files} *)

val input_inflate : in_obj_channel -> in_obj_channel

exception Error of string
       (** Exception raised by the functions above to signal errors during
           compression or decompression, or ill-formed input files. *)
