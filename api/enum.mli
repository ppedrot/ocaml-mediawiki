(** {5 Enumerations}

  This module defines enumerations. An enumeration is a lazy list where 
  accessing each element requires a (possibly dummy) asynchronous API call.
*)

type 'a t = 'a node Call.t
(** The type of enumerations. *)

and 'a node =
| Stop
| Continue of 'a * 'a t

val iter : ('a -> unit) -> 'a t -> unit Call.t
(** Asynchronous iteration over enumerations. Iteration is made callwise, so 
  it does not wait for the whole list to be available to apply the argument
  function. *)

val map : ('a -> 'b) -> 'a t -> 'b t
(** Asynchronous map over enumerations. Lazy. *)

val fold : ('a -> 'b -> 'a) -> 'a -> 'b t -> 'a Call.t
(** [fold f accu enum] folds enum using [f]. This is eager: the call evaluation 
  may trigger a lot of API calls at once, hence making it quite costly. *)

val append : 'a t -> 'a t -> 'a t
(** Append two enumerations. Lazy. *)

val filter : ('a -> bool Call.t) -> 'a t -> 'a t
(** Asynchronous filtering of enumerations. *)

val combine : 'a t -> 'b t -> ('a * 'b) t
(** Lazily combine two enumerations. *)
