open Datatypes

exception Undefined
exception Call_error of Call.error

val process : 'a Call.t -> 'a
