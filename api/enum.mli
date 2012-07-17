(** {5 Enumerations}

  This module defines enumerations. An enumeration is a lazy list where 
  accessing each element requires a (possibly dummy) asynchronous API call.
*)

(** Naming convention: in this module all function taking a function which is 
    applied to all element of the streams are suffixed by:

- [_s] when the function is monadic and calls are serialised
- [_p] when the function is monadic and calls are parallelised

*)


type +'a t
(** The type of enumerations. *)

val empty : unit -> 'a t
(** Empty enumeration. *)

val of_list : 'a list -> 'a t
(** Converts a list to a lazy enumeration. *)

val collapse : 'a t Call.t -> 'a t
(** Internalization of the lazyness. *)

val iter : ('a -> unit) -> 'a t -> unit Call.t
val iter_s : ('a -> unit Call.t) -> 'a t -> unit Call.t
val iter_p : ('a -> unit Call.t) -> 'a t -> unit Call.t
(** Iteration over enumerations. *)

val map : ('a -> 'b) -> 'a t -> 'b t
val map_s : ('a -> 'b Call.t) -> 'a t -> 'b t
val map_p : ('a -> 'b Call.t) -> 'a t -> 'b t
(** Map over enumerations. *)

val fold : ('a -> 'b -> 'a) -> 'a -> 'b t -> 'a Call.t
(** [fold f accu enum] folds enum using [f]. This is eager: the call evaluation 
  may trigger a lot of API calls at once, hence making it quite costly. *)

val append : 'a t -> 'a t -> 'a t
(** Append two enumerations. *)

val concat : 'a t t -> 'a t
(** Flattens an enum of enums. *)

val filter : ('a -> bool) -> 'a t -> 'a t
val filter_s : ('a -> bool Call.t) -> 'a t -> 'a t
(** Asynchronous filtering of enumerations. *)

val filter_map : ('a -> 'b option) -> 'a t -> 'b t
(** Combines [filter] and [map]. *)

val find  : ('a -> bool) -> 'a t -> 'a option Call.t
(** Returns an element that satifies the predicate *)
