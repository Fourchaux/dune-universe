open Lwt.Infix

module Log = Capnp_rpc.Debug.Log

module Builder = Schema.Builder
module Reader = Schema.Reader

module Conn = Capnp_rpc.CapTP.Make(Capnp_core.Endpoint_types)

type t = {
  endpoint : Endpoint.t;
  conn : Conn.t;
  xmit_queue : Capnp.Message.rw Capnp.BytesMessage.Message.t Queue.t;
  switch : Lwt_switch.t;
}

let bootstrap t = Conn.bootstrap t.conn

let async_tagged label fn =
  Lwt.async
    (fun () ->
      Lwt.catch fn
        (fun ex ->
           Log.warn (fun f -> f "Uncaught async exception in %S: %a" label Fmt.exn ex);
           Lwt.return_unit
        )
    )

let pp_msg f call =
  let open Reader in
  let call = Msg.Request.readable call in
  let interface_id = Call.interface_id_get call in
  let method_id = Call.method_id_get call in
  Capnp.RPC.Registry.pp_method f (interface_id, method_id)

let tags t = Conn.tags t.conn

(* [flush ~xmit_queue endpoint] writes each message in the queue until it is empty.
   Invariant:
     Whenever Lwt blocks or switches threads, a flush thread is running iff the
     queue is non-empty. *)
let rec flush ~switch ~xmit_queue endpoint =
  (* We keep the item on the queue until it is transmitted, as the queue state
     tells us whether there is a [flush] currently running. *)
  let next = Queue.peek xmit_queue in
  Endpoint.send endpoint next >>= function
  | Error e when Lwt_switch.is_on switch ->
    Log.warn (fun f -> f "Error sending messages: %a (will shutdown connection)" Endpoint.pp_error e);
    Lwt_switch.turn_off switch
  | Error _ -> Lwt.return_unit  (* We're shutting down *)
  | Ok () ->
    ignore (Queue.pop xmit_queue);
    if not (Queue.is_empty xmit_queue) then
      flush ~switch ~xmit_queue endpoint
    else (* queue is empty and flush thread is done *)
      Lwt.return_unit

(* Enqueue [message] in [xmit_queue] and ensure the flush thread is running. *)
let queue_send ~switch ~xmit_queue endpoint message =
  let was_idle = Queue.is_empty xmit_queue in
  Queue.add message xmit_queue;
  if was_idle then async_tagged "Message sender thread" (fun () -> flush ~switch ~xmit_queue endpoint)

let return_not_implemented t x =
  Log.info (fun f -> f ~tags:(tags t) "Returning Unimplemented");
  let open Builder in
  let m = Message.init_root () in
  let _ : Builder.Message.t = Message.unimplemented_set_reader m x in
  queue_send ~switch:t.switch ~xmit_queue:t.xmit_queue t.endpoint (Message.to_message m)

let listen t =
  let rec loop () =
    Endpoint.recv t.endpoint >>= function
    | Error e -> Lwt.return e
    | Ok msg ->
      let open Reader.Message in
      let msg = of_message msg in
      match Parse.message msg with
      | #Capnp_core.Endpoint_types.In.t as msg ->
        Log.info (fun f ->
            let tags = Capnp_core.Endpoint_types.In.with_qid_tag (Conn.tags t.conn) msg in
            f ~tags "<- %a" (Capnp_core.Endpoint_types.In.pp_recv pp_msg) msg);
        Conn.handle_msg t.conn msg;
        begin match msg with
          | `Abort _ -> Lwt.return `Aborted
          | _ -> loop ()
        end
      | `Unimplemented x as msg ->
        Log.info (fun f ->
            let tags = Capnp_core.Endpoint_types.Out.with_qid_tag (Conn.tags t.conn) x in
            f ~tags "<- Unimplemented(%a)" (Capnp_core.Endpoint_types.Out.pp_recv pp_msg) x);
        Conn.handle_msg t.conn msg;
        loop ()
      | `Not_implemented ->
        Log.info (fun f -> f "<- unsupported message type");
        return_not_implemented t msg;
        loop ()
  in
  loop ()

let connect ?offer ?(tags=Logs.Tag.empty) ~switch endpoint =
  let xmit_queue = Queue.create () in
  let queue_send msg = queue_send ~switch ~xmit_queue endpoint (Serialise.message msg) in
  let conn = Conn.create ?bootstrap:offer ~tags ~queue_send in
  Lwt_switch.add_hook (Some switch) (fun () ->
      Conn.disconnect conn (Capnp_rpc.Exception.v ~ty:`Disconnected "CapTP switch turned off");
      Lwt.return_unit
    );
  let t = {
    conn;
    endpoint;
    xmit_queue;
    switch;
  } in
  Lwt.async (fun () ->
      Lwt.catch
        (fun () ->
           listen t >|= fun (`Closed | `Aborted) -> ()
        )
        (fun ex ->
           Log.warn (fun f ->
               f ~tags "Uncaught exception handling CapTP connection: %a (dropping connection)" Fmt.exn ex
             );
           queue_send @@ `Abort (Capnp_rpc.Exception.v ~ty:`Failed (Printexc.to_string ex));
           Lwt.return_unit
        )
      >>= fun () ->
      Log.info (fun f -> f ~tags "Connection closed");
      Lwt_switch.turn_off switch
    );
  t

let disconnect t ex =
  queue_send ~switch:t.switch ~xmit_queue:t.xmit_queue t.endpoint (Serialise.message (`Abort ex));
  Lwt_switch.turn_off t.switch

let dump f t = Conn.dump f t.conn
