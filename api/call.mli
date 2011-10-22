(** {5 Abstract API calls}

  A call of type ['a t] is an abstract object to model interaction with a
  MediaWiki site. Basically, it embeds all the burden related to low-level
  management of HTTP calls and XML parsing.
*)

open Http_client

type call

type 'a t

type 'a request

type error =
| Network_Error of string
| API_Error of string
| Other_Error of exn

type 'a result =
| Unserved
| Failed of error
| Successful of 'a

exception API of string
(** Exception to be used by the API parsing functions. *)

(** {6 Monadic handling of calls} *)

val return : 'a -> 'a t
(** [return x] returns the constant call *)

val bind : 'a t -> ('a -> 'b t) -> 'b t
(** [bind m f] is the monadic bind, i.e. it extracts the result from [m] and 
  applies [f] to it. *)

val map : ('a -> 'b) -> 'a t -> 'b t
(** [map f m] applies [f] to the underlying object of [m]. *)

val http : call -> Xml.elt t
(** [http c] embeds a low-level HTTP call. It returns the XML parsed from the 
  reply of the server. The call is copied, so this is purely functional. *)

val parallel : 'a t -> 'b t -> ('a * 'b) t
(** [parrallel m n] processes [m] and [n] concurrently. *)

val join : 'a t list -> 'a list t
(** [join l] processes all the calls from the list [l] concurrently. *)

(** {6 Casting HTTP calls into abstract calls} *)

val cast : http_call -> (Nethttp.cookie -> unit) -> call
(** [cast call f] permits to deal with Set-Cookies headers of answers: [f] will 
  be fed with such cookies when [call] is processed. *)

(** {6 Request manipulation and creation} *)

val instantiate : 'a t -> 'a request
(** Instantiate any abstract call into an effective object that can be submitted
  to the server. Any exception occuring during the [bind] chaining or from any
  network error will be caught and can be analyzed through [result]. *)

val enqueue : 'a request -> pipeline -> unit
(** Push the request on the pipeline, waiting to be processed. *)

val result : 'a request -> 'a result
(** Gives back the result of the API call. *)
