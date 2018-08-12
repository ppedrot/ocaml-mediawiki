(** {5 Script functions}

  Built-in processing functions, for convenience.
*)

open Datatypes

exception Call_error of Call.error

val pipeline : Nethttp_client.pipeline
(** Default pipeline used by this module. *)

val process : 'a Call.t -> 'a
(** Process a given call, using the default pipeline. Raises {!Call_error} 
  whenever an error is encountered. *)
