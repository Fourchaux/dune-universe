val handle :
  state:State.common ->
  logger:Logger.t ->
  cb_valid_request:(unit -> unit) ->
  cb_new_leader:(unit -> unit) ->
  param:Params.request_vote_request ->
  (Cohttp.Response.t * Cohttp_lwt__.Body.t) Lwt.t
(** Invoked by candidates to gather votes ($B!x(B5.2).
 *
 * Receiver implementation:
 * 1. Reply false if term < currentTerm ($B!x(B5.1)
 * 2. If votedFor is null or candidateId, and candidate$B!G(Bs log is at
 *    least as up-to-date as receiver$B!G(Bs log, grant vote ($B!x(B5.2, $B!x(B5.4)
 *)
