(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
(* Copyright (c) 2020 Metastate AG <hello@metastate.dev>                     *)
(* Copyright (c) 2018-2021 Nomadic Labs, <contact@nomadic-labs.com>          *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

open Validation_errors

module type T = sig
  module Proto : Tezos_protocol_environment.PROTOCOL

  type t

  type operation = private {
    hash : Operation_hash.t;
    raw : Operation.t;
    protocol_data : Proto.operation_data;
  }

  val compare : operation -> operation -> int

  val parse : Operation.t -> operation tzresult

  (** Creates a new prevalidation context w.r.t. the protocol associate to the
      predecessor block . When ?protocol_data is passed to this function, it will
      be used to create the new block *)
  val create :
    Store.chain_store ->
    ?protocol_data:Bytes.t ->
    predecessor:Store.Block.t ->
    live_blocks:Block_hash.Set.t ->
    live_operations:Operation_hash.Set.t ->
    timestamp:Time.Protocol.t ->
    unit ->
    t tzresult Lwt.t

  type result =
    | Applied of t * Proto.operation_receipt
    | Branch_delayed of error list
    | Branch_refused of error list
    | Refused of error list
    | Outdated

  val apply_operation : t -> operation -> result Lwt.t

  type status = {
    applied_operations : (operation * Proto.operation_receipt) list;
    block_result : Tezos_protocol_environment.validation_result;
    block_metadata : Proto.block_header_metadata;
  }

  val status : t -> status tzresult Lwt.t

  val validation_state : t -> Proto.validation_state

  val pp_result : Format.formatter -> result -> unit
end

module Make (Proto : Tezos_protocol_environment.PROTOCOL) :
  T with module Proto = Proto = struct
  module Proto = Proto

  type operation = {
    hash : Operation_hash.t;
    raw : Operation.t;
    protocol_data : Proto.operation_data;
  }

  type t = {
    state : Proto.validation_state;
    applied : (operation * Proto.operation_receipt) list;
    live_blocks : Block_hash.Set.t;
    live_operations : Operation_hash.Set.t;
  }

  type result =
    | Applied of t * Proto.operation_receipt
    | Branch_delayed of error list
    | Branch_refused of error list
    | Refused of error list
    | Outdated

  let parse (raw : Operation.t) =
    let hash = Operation.hash raw in
    let size = Data_encoding.Binary.length Operation.encoding raw in
    if size > Proto.max_operation_data_length then
      error (Oversized_operation {size; max = Proto.max_operation_data_length})
    else
      try
        match
          Data_encoding.Binary.of_bytes_opt
            Proto.operation_data_encoding
            raw.Operation.proto
        with
        | None -> error Parse_error
        | Some protocol_data -> ok {hash; raw; protocol_data}
      with _ -> error Parse_error

  let compare op1 op2 =
    Proto.compare_operations
      {shell = op1.raw.shell; protocol_data = op1.protocol_data}
      {shell = op2.raw.shell; protocol_data = op2.protocol_data}

  let create chain_store ?protocol_data ~predecessor ~live_blocks
      ~live_operations ~timestamp () =
    (* The prevalidation module receives input from the system byt handles
       protocol values. It translates timestamps here. *)
    let {
      Block_header.shell =
        {
          fitness = predecessor_fitness;
          timestamp = predecessor_timestamp;
          level = predecessor_level;
          _;
        };
      _;
    } =
      Store.Block.header predecessor
    in
    Store.Block.context chain_store predecessor >>=? fun predecessor_context ->
    let predecessor_header = Store.Block.header predecessor in
    let predecessor_hash = Store.Block.hash predecessor in
    Block_validation.update_testchain_status
      predecessor_context
      predecessor_header
      timestamp
    >>= fun predecessor_context ->
    (match protocol_data with
    | None -> return_none
    | Some protocol_data -> (
        match
          Data_encoding.Binary.of_bytes_opt
            Proto.block_header_data_encoding
            protocol_data
        with
        | None -> failwith "Invalid block header"
        | Some protocol_data -> return_some protocol_data))
    >>=? fun protocol_data ->
    let predecessor_context =
      Shell_context.wrap_disk_context predecessor_context
    in
    Proto.begin_construction
      ~chain_id:(Store.Chain.chain_id chain_store)
      ~predecessor_context
      ~predecessor_timestamp
      ~predecessor_fitness
      ~predecessor_level
      ~predecessor:predecessor_hash
      ~timestamp
      ?protocol_data
      ()
    >>=? fun state ->
    (* FIXME arbitrary value, to be customisable *)
    return {state; applied = []; live_blocks; live_operations}

  let apply_operation pv op =
    if Operation_hash.Set.mem op.hash pv.live_operations then
      Lwt.return Outdated
    else
      protect (fun () ->
          Proto.apply_operation
            pv.state
            {shell = op.raw.shell; protocol_data = op.protocol_data})
      >|= function
      | Ok (state, receipt) -> (
          let pv =
            {
              state;
              applied = (op, receipt) :: pv.applied;
              live_blocks = pv.live_blocks;
              live_operations =
                Operation_hash.Set.add op.hash pv.live_operations;
            }
          in
          try
            let receipt =
              Data_encoding.Binary.(
                of_bytes_exn
                  Proto.operation_receipt_encoding
                  (to_bytes_exn Proto.operation_receipt_encoding receipt))
            in
            Applied (pv, receipt)
          with exn ->
            Refused
              [Validation_errors.Cannot_serialize_operation_metadata; Exn exn])
      | Error errors -> (
          match classify_errors errors with
          | `Branch -> Branch_refused errors
          | `Permanent -> Refused errors
          | `Temporary -> Branch_delayed errors)

  type status = {
    applied_operations : (operation * Proto.operation_receipt) list;
    block_result : Tezos_protocol_environment.validation_result;
    block_metadata : Proto.block_header_metadata;
  }

  let status pv =
    Proto.finalize_block pv.state >>=? fun (block_result, block_metadata) ->
    return {block_metadata; block_result; applied_operations = pv.applied}

  let validation_state {state; _} = state

  let pp_result ppf =
    let open Format in
    function
    | Applied _ -> pp_print_string ppf "applied"
    | Branch_delayed err -> fprintf ppf "branch delayed (%a)" pp_print_error err
    | Branch_refused err -> fprintf ppf "branch refused (%a)" pp_print_error err
    | Refused err -> fprintf ppf "refused (%a)" pp_print_error err
    | Outdated -> pp_print_string ppf "outdated"
end

let preapply chain_store ~user_activated_upgrades
    ~user_activated_protocol_overrides ~predecessor ~timestamp ~protocol_data
    operations =
  Store.Block.context chain_store predecessor >>=? fun predecessor_context ->
  Context.get_protocol predecessor_context >>= fun protocol ->
  (match Registered_protocol.get protocol with
  | None ->
      (* FIXME. *)
      (* This should not happen: it should be handled in the validator. *)
      failwith
        "Prevalidation: missing protocol '%a' for the current block."
        Protocol_hash.pp_short
        protocol
  | Some protocol -> return protocol)
  >>=? fun (module Proto) ->
  let module Prevalidation = Make (Proto) in
  let apply_operation_with_preapply_result preapp t op =
    let open Preapply_result in
    Prevalidation.apply_operation t op >>= function
    | Applied (t, _) ->
        let applied = (op.hash, op.raw) :: preapp.applied in
        Lwt.return ({preapp with applied}, t)
    | Branch_delayed errors ->
        let branch_delayed =
          Operation_hash.Map.add op.hash (op.raw, errors) preapp.branch_delayed
        in
        Lwt.return ({preapp with branch_delayed}, t)
    | Branch_refused errors ->
        let branch_refused =
          Operation_hash.Map.add op.hash (op.raw, errors) preapp.branch_refused
        in
        Lwt.return ({preapp with branch_refused}, t)
    | Refused errors ->
        let refused =
          Operation_hash.Map.add op.hash (op.raw, errors) preapp.refused
        in
        Lwt.return ({preapp with refused}, t)
    | Outdated -> Lwt.return (preapp, t)
  in
  Store.Chain.compute_live_blocks chain_store ~block:predecessor
  >>=? fun (live_blocks, live_operations) ->
  Prevalidation.create
    chain_store
    ~protocol_data
    ~predecessor
    ~live_blocks
    ~live_operations
    ~timestamp
    ()
  >>=? fun validation_state ->
  List.fold_left_s
    (fun (acc_validation_passes, acc_validation_result_rev, acc_validation_state)
         operations ->
      List.fold_left_s
        (fun (acc_validation_result, acc_validation_state) op ->
          match Prevalidation.parse op with
          | Error _ ->
              (* FIXME *)
              Lwt.return (acc_validation_result, acc_validation_state)
          | Ok op ->
              apply_operation_with_preapply_result
                acc_validation_result
                acc_validation_state
                op)
        (Preapply_result.empty, acc_validation_state)
        operations
      >>= fun (new_validation_result, new_validation_state) ->
      (* Applied operations are reverted ; revert to the initial ordering *)
      let new_validation_result =
        {
          new_validation_result with
          applied = List.rev new_validation_result.applied;
        }
      in
      Lwt.return
        ( acc_validation_passes + 1,
          new_validation_result :: acc_validation_result_rev,
          new_validation_state ))
    (0, [], validation_state)
    operations
  >>= fun (validation_passes, validation_result_list_rev, validation_state) ->
  Lwt.return (List.rev validation_result_list_rev, validation_state)
  >>= fun (validation_result_list, validation_state) ->
  let operations_hash =
    Operation_list_list_hash.compute
      (List.rev_map
         (fun r ->
           Operation_list_hash.compute (List.map fst r.Preapply_result.applied))
         validation_result_list_rev)
  in
  Prevalidation.status validation_state >>=? fun {block_result; _} ->
  let pred_shell_header = Store.Block.shell_header predecessor in
  let level = Int32.succ pred_shell_header.level in
  Block_validation.may_patch_protocol
    ~user_activated_upgrades
    ~user_activated_protocol_overrides
    ~level
    block_result
  >>= fun {fitness; context; message; _} ->
  Store.Block.protocol_hash chain_store predecessor >>=? fun pred_protocol ->
  let context = Shell_context.unwrap_disk_context context in
  Context.get_protocol context >>= fun protocol ->
  let proto_level =
    if Protocol_hash.equal protocol pred_protocol then
      pred_shell_header.proto_level
    else (pred_shell_header.proto_level + 1) mod 256
  in
  let pred_block_hash = Store.Block.hash predecessor in
  let shell_header : Block_header.shell_header =
    {
      level;
      proto_level;
      predecessor = pred_block_hash;
      timestamp;
      validation_passes;
      operations_hash;
      fitness;
      context = Context_hash.zero (* place holder *);
    }
  in
  (if Protocol_hash.equal protocol pred_protocol then return (context, message)
  else
    match Registered_protocol.get protocol with
    | None ->
        fail
          (Block_validator_errors.Unavailable_protocol
             {block = pred_block_hash; protocol})
    | Some (module NewProto) ->
        let context = Shell_context.wrap_disk_context context in
        NewProto.init context shell_header >>=? fun {context; message; _} ->
        let context = Shell_context.unwrap_disk_context context in
        return (context, message))
  >>=? fun (context, message) ->
  ((match Registered_protocol.get pred_protocol with
   | None ->
       fail
         (Block_validator_errors.Unavailable_protocol
            {block = pred_block_hash; protocol = pred_protocol})
   | Some (module Proto) -> return Proto.environment_version)
   >>=? function
   | Protocol.V0 -> return context
   | Protocol.V1 | Protocol.V2 | Protocol.V3 -> (
       (* Block and operation metadata hashes may not be set on
          the testchain genesis block and activation block, even
          when they are using environment V1, they contain no
          operations. *)
       let is_from_genesis =
         (Store.Block.header predecessor).shell.validation_passes = 0
       in
       (match Store.Block.all_operations_metadata_hash predecessor with
       | None ->
           if is_from_genesis then return context
           else fail @@ Missing_operation_metadata_hashes pred_block_hash
       | Some hash ->
           Context.add_predecessor_ops_metadata_hash context hash >|= ok)
       >>=? fun context ->
       match Store.Block.block_metadata_hash predecessor with
       | None ->
           if is_from_genesis then return context
           else fail @@ Missing_operation_metadata_hashes pred_block_hash
       | Some predecessor_block_metadata_hash ->
           Context.add_predecessor_block_metadata_hash
             context
             predecessor_block_metadata_hash
           >|= ok))
  >>=? fun context ->
  let context = Context.hash ?message ~time:timestamp context in
  return ({shell_header with context}, validation_result_list)
