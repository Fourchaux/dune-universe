(** Cap'n Proto RPC using the Cap'n Proto serialisation and Lwt for concurrency. *)

open Capnp.RPC

include (module type of Capnp.BytesMessage)

type 'a or_error = ('a, Capnp_rpc.Error.t) result

module StructRef : sig
  (** A promise for a response structure.
      You can use the generated [_get_pipelined] functions on a promise to get
      a promise for a capability inside the promise, and then pipeline messages
      to that promise without waiting for the response struct to arrive. *)

  type 'a t
  (** An ['a t] is a reference to a response message (that may not have arrived yet)
      with content type ['a]. *)

  val inc_ref : 'a t -> unit
  (** [inc_ref t] increases the reference count on [t] by one. *)

  val dec_ref : 'a t -> unit
  (** [dec_ref t] reduces the reference count on [t] by one.
      When the count reaches zero, this result must never be used again.
      If the results have not yet arrived when the count reaches zero, we send
      a cancellation request (which may or may not succeed). As soon as the
      results are available, they are released. *)
end

module Capability : sig
  (** A capability is a reference to an object, or to a promise for an object.
      You can invoke methods on a capability even while it is still only a
      promise. *)

  type +'a t
  (** An ['a t] is a capability reference to a service of type ['a]. *)

  val broken : Capnp_rpc.Exception.t -> 'a t
  (** [broken ex] is a broken capability, with problem [ex].
      Any attempt to call methods on it will fail with [ex]. *)

  val when_broken : (Capnp_rpc.Exception.t -> unit) -> 'a t -> unit
  (** [when_broken fn x] calls [fn problem] when [x] becomes broken.
      If [x] is already broken, [fn] is called immediately.
      If [x] can never become broken (e.g. it is a near ref), this does nothing.
      If [x]'s ref-count reaches zero without [fn] being called, it will never
      be called. *)

  val problem : 'a t -> Capnp_rpc.Exception.t option
  (** [problem t] is [Some ex] if [t] is broken, or [None] if it is still
      believed to be healthy. Once a capability is broken, it will never
      work again and any calls made on it will fail with exception [ex]. *)

  val wait_until_settled : 'a t -> unit Lwt.t
  (** [wait_until_settled x] resolves once [x] is a "settled" (non-promise) reference.
      If [x] is a near, far or broken reference, this returns immediately.
      If it is currently a local or remote promise, it waits until it isn't.
      [wait_until_settled] takes ownership of [x] until it returns (you must not
      [dec_ref] it before then). *)

  val equal : 'a t -> 'a t -> (bool, [`Unsettled]) result
  (** [equal a b] indicates whether [a] and [b] designate the same settled service.
      Returns [Error `Unsettled] if [a] or [b] is still a promise (and they therefore
      may yet turn out to be equal when the promise resolves). *)

  module Request : sig
    type 'a t
    (** An ['a t] is a builder for the out-going request's payload. *)

    val create : (Capnp.Message.rw Slice.t -> 'a) -> 'a t * 'a
    (** [create init] is a fresh request payload and contents builder.
        Use one of the generated [init_pointer] functions for [init]. *)

    val create_no_args : unit -> 'a t
    (** [create_no_args ()] is a payload with no content. *)

    val release : 'a t -> unit
    (** Clear the exported refs, dropping their ref-counts. This is called automatically
        when you send a message, but you might need it if you decide to abort. *)
  end

  val call : 't t -> ('t, 'a, 'b) MethodID.t -> 'a Request.t -> 'b StructRef.t
  (** [call target m req] invokes [target#m req] and returns a promise for the result.
      Messages may be sent to the capabilities that will be in the result
      before the result arrives - they will be pipelined to the service
      responsible for resolving the promise. The caller must call [StructRef.dec_ref]
      when finished with the result (consider using one of the [call_*] functions below
      instead for a simpler interface). *)

  val call_and_wait : 't t -> ('t, 'a, 'b StructStorage.reader_t) MethodID.t ->
    'a Request.t -> ('b StructStorage.reader_t * (unit -> unit)) or_error Lwt.t
  (** [call_and_wait t m req] does [call t m req] and waits for the response.
      This is simpler than using [call], but doesn't support pipelining
      (you can't use any capabilities in the response in another message until the
      response arrives).
      On success, it returns [Ok (response, release_response_caps)].
      Call [release_response_caps] when done with the results, to release any capabilities it might
      contain that you didn't use (remembering that future versions of the protocol might add
      new optional capabilities you don't know about yet).
      If you don't need any capabilities from the result, consider using [call_for_value] instead.
      Doing [Lwt.cancel] on the result will send a cancel message to the target
      for remote calls. *)

  val call_for_value : 't t -> ('t, 'a, 'b StructStorage.reader_t) MethodID.t ->
    'a Request.t -> 'b StructStorage.reader_t or_error Lwt.t
  (** [call_for_value t m req] is similar to [call_and_wait], but automatically
      releases any capabilities in the response before returning. Use this if
      you aren't expecting any capabilities in the response. *)

  val call_for_value_exn : 't t -> ('t, 'a, 'b StructStorage.reader_t) MethodID.t ->
    'a Request.t -> 'b StructStorage.reader_t Lwt.t
  (** Wrapper for [call_for_value] that turns errors into Lwt failures. *)

  val call_for_unit : 't t -> ('t, 'a, 'b StructStorage.reader_t) MethodID.t ->
    'a Request.t -> unit or_error Lwt.t
  (** Wrapper for [call_for_value] that ignores the result. *)

  val call_for_unit_exn : 't t -> ('t, 'a, 'b StructStorage.reader_t) MethodID.t ->
    'a Request.t -> unit Lwt.t
  (** Wrapper for [call_for_unit] that turns errors into Lwt failures. *)

  val call_for_caps : 't t -> ('t, 'a, 'b StructStorage.reader_t) MethodID.t ->
    'a Request.t -> ('b StructRef.t -> 'c) -> 'c
  (** [call_for_caps target m req extract] is a wrapper for [call] that passes the results promise to
      [extract], which should extract any required capability promises from it.
      In the common case where you want a single cap "foo" from the result, use
      [call_for_caps target m req Results.foo_get_pipelined].
      When the remote call finally returns, the result will be released automatically. *)

  type 'a resolver
  (** An ['a resolver] can be used to resolve a promise for an ['a]. It can only be used once. *)

  val promise : unit -> 'a t * 'a resolver
  (** [promise ()] returns a fresh local promise and a resolver for it.
      Any calls made on the promise will be queued until it is resolved. *)

  val resolve_ok : 'a resolver -> 'a t -> unit
  (** [resolve_ok r x] resolves [r]'s promise to [x]. [r] takes ownership of [x]
      (the caller must use [inc_ref] first if they want to continue using it). *)

  val resolve_exn : 'a resolver -> Capnp_rpc.Exception.t -> unit
  (** [resolve_exn r x] breaks [r]'s promise with exception [x]. *)

  val inc_ref : _ t -> unit
  (** [inc_ref t] increases the ref-count on [t] by one. *)

  val dec_ref : _ t -> unit
  (** [dec_ref t] decreases the ref-count on [t] by one. When the count reaches zero,
      the capability is released. This may involve sending a notification to a remote
      peer. Any time you extract a capability from a struct or struct promise,
      it must eventually be freed by calling [dec_ref] on it. *)

  val pp : 'a t Fmt.t
end

module Sturdy_ref : sig
  type +'a t
  (** An off-line (persistent) capability reference.

      A sturdy ref contains all the information necessary to get a live reference to a service:

      - The network address of the hosting vat (e.g. TCP host and port)
      - A way to authenticate the hosting vat (e.g. a fingerprint of the vat's public key)
      - A way to identify the target service within the vat and prove permission to access it
        (e.g. a "Swiss number")
    *)

  val connect : 'a t -> ('a Capability.t, Capnp_rpc.Exception.t) result Lwt.t
  (** [connect t] returns a live reference to [t]'s service. *)

  val connect_exn : 'a t -> 'a Capability.t Lwt.t
  (** [connect_exn] is a wrapper for [connect] that returns a failed Lwt thread on error. *)

  val reader :
    ('a StructStorage.reader_t -> Capnp.MessageSig.ro Slice.t option) ->
    'a StructStorage.reader_t -> Uri.t
  (** [reader accessor] is a field accessor for reading a sturdy ref.
      e.g. if [sr_get] is a generated field accessor for an AnyPointer field, then
      [reader Reader.Struct.sr_get] is an accessor that treats it as a SturdyRef field.
      todo: This should really return a sturdy ref, not a URI, but that requires a change
      to the spec to add a sturdy ref cap-descriptor table entry type. *)

  val builder :
    ('a StructStorage.builder_t -> Capnp.MessageSig.rw Slice.t) ->
    'a StructStorage.builder_t -> _ t -> unit
  (** [builder setter] converts a generated AnyPointer field setter [setter] to a SturdyRef
      setter. Use it to add a SturdyRef to a message with [builder Params.sr_get params sr]. *)

  val cast : 'a t -> 'b t
end

module Service : sig
  (** Functions for service implementors. *)

  type ('a, 'b) method_t = 'a -> (unit -> unit) -> 'b StructRef.t
  (** An ('a, 'b) method_t is a method implementation that takes
      a reader for the parameters and
      a function to release the capabilities in the parameters,
      and returns a promise for the results. *)

  module Response : sig
    type 'b t
    (** An ['a t] is a builder for the out-going response. *)

    val create : (Capnp.Message.rw Slice.t -> 'a) -> 'a t * 'a
    (** [create init] is a fresh response and contents builder.
        Use one of the generated [init_pointer] functions for [init]. *)

    val create_empty : unit -> 'a t
    (** [empty ()] is an empty response. *)

    val release : 'a t -> unit
    (** Clear the exported refs, dropping their ref-counts. This is called automatically
        when you send a message, but you might need it if you decide to abort. *)
  end

  val return : 'a Response.t -> 'a StructRef.t
  (** [return r] wraps up a simple local result as a promise. *)

  val return_empty : unit -> 'a StructRef.t
  (** [return_empty ()] is a promise for a response with no payload. *)

  val return_lwt : (unit -> 'a Response.t or_error Lwt.t) -> 'a StructRef.t
  (** [return_lwt fn] is a local promise for the result of Lwt thread [fn ()].
      If [fn ()] fails, the error is logged and an "Internal error" returned to the caller.
      If it returns an [Error] value then that error is returned to the caller.
      Note that this does not support pipelining (any messages sent to the response
      will be queued locally until it [fn] has produced a result), so it may be better
      to return immediately a result containing a promise in some cases. *)

  val fail : ?ty:Capnp_rpc.Exception.ty -> ('a, Format.formatter, unit, 'b StructRef.t) format4 -> 'a
  (** [fail msg] is an exception with reason [msg]. *)
end

module S = S

module Endpoint = Endpoint
module Two_party_network = Two_party_network
module Auth = Auth
module Tls_wrapper = Tls_wrapper

module Restorer : sig
  module Id : sig
    type t
    (** The object ID passed in the Cap'n Proto Bootstrap message. *)

    val generate : unit -> t
    (** [generate ()] is a fresh unguessable service ID.
        Note: you must initialise `Nocrypto`'s entropy before calling this
        (you will get a runtime error if you forget). *)

    val derived : secret:string -> string -> t
    (** [derived ~secret name] is a service ID based on [secret] and [name].
        It is calculated as [SHA256.hmac secret name].
        [secret] could be the hash of a private key file, for example. *)

    val public : string -> t
    (** [public name] is the service ID [name].
        This may be useful for interoperability with non-secure clients that expect
        to use a plain-text service ID (e.g. "calculator"). It could also be
        useful if [name] is some unguessable token you have generated yourself. *)

    val digest : Auth.hash -> t -> string
    (** [digest h id] is the digest [h id].

        Since [id] is normally a secret token, we must be careful not to allow
        timing attacks (taking a slightly different amount of time to return an
        error depending on how much of the ID the caller guessed correctly).
        Taking a secure hash of the value first is one way to avoid this, since
        revealing the hash isn't helpful to the attacker. *)

    val to_string : t -> string
    (** [to_string t] is the raw bytes of [t]. *)

    val pp : t Fmt.t
    val equal : t -> t -> bool
  end

  (** {2 Resolutions} *)

  type resolution
  (** Internally, this is just [('a Capability.t, Capnp_rpc.Exception.t) result] but the
      types work out better having it abstract. *)

  val grant : 'a Capability.t -> resolution
  (** [grant x] is [Ok x]. *)

  val reject : Capnp_rpc.Exception.t -> resolution
  (** [reject x] is [Error x]. *)

  val unknown_service_id : resolution
  (** [unknown_service_id] is a standard rejection message. *)

  (** {2 Restorers} *)

  type t
  (** A restorer looks up live capabilities from service IDs. *)

  val none : t
  (** [none] is a restorer that rejects everything. *)

  val single : Id.t -> 'a Capability.t -> t
  (** [single id cap] is a restorer that responds to [id] with [cap] and
      rejects everything else. *)

  module type LOADER = sig
    type t
    (** A user-provided function to restore services from persistent storage. *)

    val hash : t -> Auth.hash
    (** [hash t] is the hash to apply to a [Restorer.Id.t] to get the storage key,
        which is passed to [load].
        You should use the [hash id] value to find the item. Note that [hash]
        is purely a local security measure - remote peers only see the ID. *)

    val make_sturdy : t -> Id.t -> Uri.t
    (** [make_sturdy t id] converts an ID to a full URI, by adding the
        hosting vat's address and fingerprint. *)

    val load : t -> 'a Sturdy_ref.t -> string -> resolution Lwt.t
    (** [load t sr digest] is called to restore the service with key [digest].
        [sr] is a sturdy ref that refers to the service, which the service
        might want to hand out to clients.
        Note that connecting to [sr] will block until the loader has returned.
        The result is cached until its ref-count reaches zero, so the table
        will never allow two live capabilities for a single [Id.t] at once. It
        will also not call [load] twice in parallel for the same digest. *)
  end

  module Table : sig
    type t
    (** A restorer that keeps a hashtable mapping IDs to capabilities in memory. *)

    val create : (Id.t -> Uri.t) -> t
    (** [create make_sturdy] is a new in-memory-only table.
        [make_sturdy id] converts an ID to a full URI, by adding the
        hosting vat's address and fingerprint. *)

    val of_loader : (module LOADER with type t = 'loader) -> 'loader -> t
    (** [of_loader (module Loader) l] is a new caching table that uses
        [Loader.load l sr (Loader.hash id)] to restore services that aren't in the cache. *)

    val add : t -> Id.t -> 'a Capability.t -> unit
    (** [add t id cap] adds a mapping to [t].
        It takes ownership of [cap] (it will call [Capability.dec_ref cap] on [clear]). *)

    val sturdy_ref : t -> Id.t -> 'a Sturdy_ref.t
    (** [sturdy_ref t id] is a sturdy ref that can be used to restore service [id]. *)

    val remove : t -> Id.t -> unit
    (** [remove t id] removes [id] from [t].
        It decrements the capability's ref count if it was added manually with [add]. *)

    val clear : t -> unit
    (** [clear t] removes all entries from the table. *)
  end

  val of_table : Table.t -> t

  val restore : t -> Id.t -> ('a Capability.t, Capnp_rpc.Exception.t) result Lwt.t
  (** [restore t id] restores [id] using [t].
      You don't normally need to call this directly, as the Vat will do it automatically. *)
end

module type VAT_NETWORK = S.VAT_NETWORK with
  type 'a capability := 'a Capability.t and
  type restorer := Restorer.t and
  type service_id := Restorer.Id.t and
  type 'a sturdy_ref := 'a Sturdy_ref.t

module Networking (N : S.NETWORK) (Flow : Mirage_flow_lwt.S) : VAT_NETWORK with
  module Network = N and
  type flow = Flow.flow

module Capnp_address = Capnp_address

(**/**)

module Untyped : sig
  (** This module is only for use by the code generated by the capnp-ocaml
      schema compiler. The generated code provides type-safe wrappers for
      everything here. *)

  type abstract_method_t

  val abstract_method : ('a StructStorage.reader_t, 'b) Service.method_t -> abstract_method_t

  val struct_field : 'a StructRef.t -> int -> 'b StructRef.t

  val capability_field : 'a StructRef.t -> int -> 'b Capability.t

  class type generic_service = object
    method dispatch : interface_id:Uint64.t -> method_id:int -> abstract_method_t
    method release : unit
    method pp : Format.formatter -> unit
  end

  val local : #generic_service -> 'a Capability.t

  val get_cap : Capnp.MessageSig.attachments -> Uint32.t -> _ Capability.t
  val add_cap : Capnp.MessageSig.attachments -> _ Capability.t -> Uint32.t
  val clear_cap : Capnp.MessageSig.attachments -> Uint32.t -> unit

  val unknown_interface : interface_id:Uint64.t -> abstract_method_t
  val unknown_method : interface_id:Uint64.t -> method_id:int -> abstract_method_t
end

(**/**)

module Persistence : sig
  class type ['a] persistent = object
    method save : ('a Sturdy_ref.t, Capnp_rpc.Exception.t) result Lwt.t
  end

  val with_persistence :
    ('a #persistent) ->
    ('impl -> 'a Capability.t) ->
    (#Untyped.generic_service as 'impl) ->
    'a Capability.t
  (** [with_persistence persist Service.Foo.local obj] is like [Service.Foo.local obj], but the
      resulting service also handles the Cap'n Proto persistence protocol, using [persist]. *)

  val with_sturdy_ref :
    'a Sturdy_ref.t ->
    ('impl -> 'a Capability.t) ->
    (#Untyped.generic_service as 'impl) ->
    'a Capability.t
  (** [with_sturdy_ref sr Service.Foo.local obj] is like [Service.Foo.local obj],
      but responds to [save] calls by returning [sr]. *)

  val save : 'a Capability.t -> (Uri.t, Capnp_rpc.Error.t) result Lwt.t
  (** [save cap] calls the persistent [save] method on [cap].
      Note that not all capabilities can be saved.
      todo: this should return an ['a Sturdy_ref.t]; see {!Sturdy_ref.reader}. *)

  val save_exn : 'a Capability.t -> Uri.t Lwt.t
  (** [save_exn] is a wrapper for [save] that returns a failed thread on error. *)
end
