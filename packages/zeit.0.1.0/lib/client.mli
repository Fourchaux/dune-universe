type t

val make :
     ?cohttp_call:(   Cohttp.Code.meth
                   -> Cohttp.Header.t
                   -> Uri.t
                   -> body:string
                   -> (Cohttp.Response.t * Cohttp_lwt.Body.t) Lwt.t)
  -> token:string
  -> unit
  -> t

val list_deployments : t -> (Deployment.t list, Error.t) result Lwt.t

val post_file : t -> string -> (string, Error.t) result Lwt.t

val create_deployment :
     t
  -> name:string
  -> files:(string * string * int) list
  -> (Deployment.Api_responses.create_result, Error.t) result Lwt.t
