open Http_client

(** {1 Abstract definition of API calls} *)

(** A call of type ['a t] is an abstract object to model interaction with a
    MediaWiki site. Basically, it embeds all the burden related to low-level
    management of HTTP calls and XML parsing. *)

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

(** {1 Monadic handling of calls} *)

val return : 'a -> 'a t
(** [return x] returns the constant call *)

val bind : 'a t -> ('a -> 'b t) -> 'b t
(** [bind m f] is the monadic bind, i.e. it extracts the result from [m] and 
  applies [f] to it. *)

val http : call -> Xml.elt t
(** [http c] embeds a low-level HTTP call. It returns the XML parsed from the 
  reply of the server. The call is copied, so this is purely functional. *)

(** {1 Casting HTTP calls into abstract calls} *)

val cast : http_call -> (Cookie.t -> unit) -> call
(** [cast c f] permits to deal with Set-Cookies headers of answers: [f] will be
  fed with such cookies. *)

(** {1 Request manipulation and creation} *)

val instantiate : 'a t -> 'a request
(** Instantiate any abstract call into an effective object that can be submitted
  to the server. Any exception occuring during the [bind] chaining or from any
  network error will be caught and can be analyzed through [result]. *)

val enqueue : 'a request -> pipeline -> unit
(** Push the request on the pipeline, waiting to be processed. *)

val result : 'a request -> 'a result
(** Gives back the result of the API call. *)
