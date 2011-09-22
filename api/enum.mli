(** {1 Enumeration type and functions} *)

type 'a t = 'a node Call.t
(* Type of enumerations. An enumeration is a lazy list where accessing each 
  element requires an (possibly dummy) asynchronous API call. *)

and 'a node =
| Stop
| Continue of 'a * 'a t

val iter : ('a -> unit) -> 'a t -> unit Call.t
(** Asynchronous iteration over enumerations. Iteration is made callwise, so 
  it does not wait for the whole list to be available to finish. *)

val map : ('a -> 'b) -> 'a t -> 'b t
(** Asynchronous map over enumerations. This is a lazy operation. *)

val fold : ('a -> 'b -> 'a) -> 'a -> 'b t -> 'a Call.t
(** [fold f accu enum] folds enum using [f]. This is eager: the call evaluation 
  may trigger a lot of API calls at once, hence making it quite costly. *)
