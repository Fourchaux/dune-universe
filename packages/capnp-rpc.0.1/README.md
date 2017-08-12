## OCaml Cap'n Proto RPC library

Status: RPC Level 1 with two-party networking is complete.

Copyright 2017 Docker, Inc.
See [LICENSE.md](LICENSE.md) for details.

### Overview

[Cap'n Proto][] is a capability-based RPC system with bindings for many languages.
Some key features:

- APIs are defined using a schema file, which is compiled to create bindings for different languages automatically.

- Schemas can be upgraded in many ways without breaking backwards-compatibility.

- Messages are built up and read in-place, making it very fast.

- Messages can contain *capability references*, allowing the sender to share access to a service. Access control is handled automatically.

- Messages can be *pipelined*. For example, you can ask one service where another one is, and then immediately start calling methods on it. The requests will be sent to the first service, which will either handle them (in the common case where the second service is in the same place) or forward them until you can establish a direct connection.

- Messages are delivered in [E-Order][], which means that messages sent over a reference will arrive in the order in which they were sent, even if the path they take through the network gets optimised at some point.

This library should be used with the [capnp-ocaml][] schema compiler, which generates bindings from schema files.


### Status

The library been only lightly used in real systems, but has unit tests and AFL fuzz tests that cover most of the core logic.

All level 1 features are implemented.

The library does not currently provide support for establishing new encrypted network connections.
Instead, the user of the library is responsible for creating a secure channel to the target service and then giving it to the library.
For example, a channel could be a local Unix-domain socket (created with `socketpair`) or a TCP connection with a TLS wrapper.
See `test-bin/calc.ml` for an example program that can provide or consume a service over a Unix domain socket.

Level 3 support is not implemented yet, so if host Alice has connections to hosts Bob and Carol and passes an object hosted at Bob to Carol, the resulting messages between Carol and Bob will be routed via Alice.


### Building

To build, you will need a platform with the capnproto package available (e.g. Debian >= 9). Then:

    git clone https://github.com/mirage/capnp-rpc.git
    cd capnp-rpc
    opam pin add -nyk git capnp-rpc .
    opam pin add -nyk git capnp-rpc-lwt .
    opam pin add -nyk git capnp-rpc-unix .
    opam depext capnp-rpc-lwt alcotest
    opam install --deps-only -t capnp-rpc-unix
    make test

The `examples` directory contains some test services.
Running `make test` will run through the tests in `test-lwt/test.ml`, which make use of the examples.

If you have trouble building, you can build it with Docker from a known-good state using `docker build .`.

### Structure of the library

The code is split into three libraries:

- `capnp-rpc` contains the logic of the [Cap'n Proto RPC Protocol][], but does not depend on any particular serialisation.
  The tests in the `test` directory test the logic using a simple representation where messages are OCaml data-structures
  (defined in `capnp-rpc/message_types.ml`).

- `capnp-rpc-lwt` instantiates the `capnp-rpc` functor using the Cap'n Proto serialisation for messages and Lwt for concurrency.
  The tests in `test-lwt` test this by sending Cap'n Proto messages over a Unix-domain socket.

- `capnp-rpc-unix` adds helper functions for parsing command-line arguments and setting up connections over Unix sockets.

Users of the library will normally want to use `capnp-rpc-lwt` and, in most cases, `capnp-rpc-unix`.

### Conceptual model

An RPC system contains multiple communicating actors (just ordinary OCaml objects).
An actor can hold *capabilities* to other objects.
A capability here is just a regular OCaml object pointer.

Essentially, each object provides a `call` method, which takes:

- some pure-data message content (typically an array of bytes created by the Cap'n Proto serialisation), and
- an array of pointers to other objects (providing the same API).

The data part of the message says which method to invoke and provides the arguments.
Whenever an argument needs to refer to another object, it gives the index of a pointer in the pointers array.

For example, a call to a method that transfers data between two stores might look something like this:

```yaml
- Content:
  - InterfaceID: xxx
  - MethodID: yyy
  - Params:
    - Source: 0
    - Target: 1
- Pointers:
  - <source>
  - <target>
```

A call also takes a *resolver*, which it will call with the answer when it's ready.
The answer will also contain data and pointer parts.

On top of this basic model the Cap'n Proto schema compiler ([capnp-ocaml]) generates a typed API, so that application code can only generate or attempt to consume messages that match the schema.
Application code does not need to worry about interface or method IDs, for example.

This might seem like a rather clumsy system, but it has the advantage that such messages can be sent not just within a process,
like regular OCaml method calls, but also over the network to remote objects.

The network is made up of communicating "vats" of objects.
You can think of a Unix process as a single vat.
The vats are peers - there is no difference between a "client" and a "server" at the protocol level.
However, a vat may choose to offer a public object, called its "bootstrap" service, and you might like to think of such vats as servers.

When a connection is established between two vats, each can choose to ask for the other's bootstrap object.
The capability they get back is a proxy object that acts like a local service but forwards all calls over the network.
When a message is sent that contains pointers, the RPC system holds onto the pointers and makes each object available over that network connection.
Each vat only needs to expose at most a single bootstrap object,
since the bootstrap object can provide methods to get access to any other required services.

All shared objects are scoped to the network connection, and will be released if the connection is closed for any reason.

The RPC system is smart enough that if you export a local object to a remote service and it later exports the same object back to you, it will switch to sending directly to the local service (once any pipelined messages in flight have been delivered).

You can also export an object that you received from a third-party, and the receiver will be able to use it.
Ideally, the receiver should be able to establish a direct connection to the third-party, but
this isn't yet implemented and instead the RPC system will forward messages and responses in this case.

### Creating your own services

Start by writing a [Cap'n Proto schema file][schema].
For example, here is a very simple echo service:

```capnp
interface Echo {
  ping @0 (msg :Text) -> (reply :Text);
}
```

This defines the `Echo` interface as having a single method called `ping`
which takes a struct containing a text field called `msg`
and returns a struct containing another text field called `reply`.

Save this as `echo_api.capnp` and compile it using capnp:

```
$ capnp compile echo_api.capnp -o ocaml
echo_api.capnp:1:1: error: File does not declare an ID.  I've generated one for you.
Add this line to your file:
@0xb287252b6cbed46e;
```

Every interface needs a globally unique ID.
If you don't have one, capnp will pick one for you, as shown above.
Add the line to the start of the file to get:

```capnp
@0xb287252b6cbed46e;

interface Echo {
  ping @0 (msg :Text) -> (reply :Text);
}
```

Now it can be compiled:

```
$ capnp compile echo_api.capnp -o ocaml
echo_api.capnp --> echo_api.mli echo_api.ml
```

The next step is to implement a client and server (in a new `echo.ml` file) using the generated `Echo_api` OCaml module.

For the server, you should inherit from the generated `Api.Service.Echo.service` class:

```ocaml
module Api = Echo_api.MakeRPC(Capnp_rpc_lwt)

open Lwt.Infix
open Capnp_rpc_lwt

let service =
  let module Echo = Api.Service.Echo in
  Echo.local @@ object
    inherit Echo.service

    method ping_impl params release_param_caps =
      let open Echo.Ping in
      let msg = Params.msg_get params in
      release_param_caps ();
      let response, results = Service.Response.create Results.init_pointer in
      Results.reply_set results ("echo:" ^ msg);
      Service.return response
  end
```

The first line (`module Api`) instantiates the generated code to use this library's RPC implementation.

`service` must provide one OCaml method for each method defined in the schema file, with `_impl` on the end of each one.

There's a bit of ugly boilerplate here, but it's quite simple:

- The `Api.Service.Echo.Ping` module defines the server-side API for the `ping` method.
- `Ping.Params` is a reader for the parameters.
- `Ping.Results` is a builder for the results.
- `msg` is the string value of the `msg` field.
- `release_param_caps` releases any capabilities passed in the parameters.
  In this case there aren't any, but remember that a client using some future
  version of this protocol might pass some optional capabilities, and so you
  should always free them anyway.
- `response` is the complete message to be sent back, and `results` is the data part of it.
- `Service.Response.create Results.init_pointer` creates a new response message, using `Results.init_pointer` to initialise the payload contents.
- `Service.return` returns the results immediately (like `Lwt.return`).

The client implementation is similar, but uses `Api.Client` instead of `Api.Service`.
Here, we have a *builder* for the parameters and a *reader* for the results.
`Api.Client.Echo.Ping.method_id` is a globally unique identifier for the ping method.

```ocaml
module Client = struct
  module Echo = Api.Client.Echo

  let ping t msg =
    let open Echo.Ping in
    let request, params = Capability.Request.create Params.init_pointer in
    Params.msg_set params msg;
    Capability.call_for_value_exn t method_id request >|= Results.reply_get
end
```

`Capability.call_for_value_exn` sends the request message to the service and waits for the response to arrive.
If the response is an error, it raises an exception.
`Results.reply_get` extracts the `reply` field of the result.

We don't need to release the capabilities of the results, as `call_for_value_exn` does that automatically.
We'll see how to handle capabilities later.

With the boilerplate out of the way, we can now write a `main.ml` to test it:

```ocaml
open Lwt.Infix

let () =
  Lwt_main.run begin
    let service = Echo.service in
    Echo.Client.ping service "foo" >>= fun reply ->
    Fmt.pr "Got reply %S@." reply;
    Lwt.return_unit
  end
```

If you're building with jbuilder, here's a suitable `jbuild` file:

```
(jbuild_version 1)

(executable (
  (name main)
  (libraries (capnp-rpc-lwt capnp-rpc-unix))
  (flags (:standard -w -53-55))
))

(rule
 ((targets (echo_api.ml echo_api.mli))
  (deps (echo_api.capnp))
  (action  (run capnpc -o ocaml ${<}))))
```

The service is now usable:

```bash
$ opam install capnp-rpc-unix
$ jbuilder build --dev main.exe
$ ./_build/default/main.exe
Got reply "echo:foo"
```

This isn't very exciting, so let's add some capabilities to the protocol...

### Passing capabilities

```capnp
@0xb287252b6cbed46e;

interface Callback {
  log @0 (msg :Text) -> ();
}

interface Echo {
  ping      @0 (msg :Text) -> (reply :Text);
  heartbeat @1 (msg :Text, callback :Callback) -> ();
}
```

This version of the protocol adds a `heartbeat` method.
Instead of returning the text directly, it will send it to a callback at regular intervals.

Run `capnp compile` again to update the generated files
(if you're using the jbuild file then this will happen automatically and you should delete the generated `echo_api.ml` and `echo_api.mli` files from the source directory instead).

The new `heartbeat_impl` method looks like this:

```ocaml
    method heartbeat_impl params release_params =
      let open Echo.Heartbeat in
      let msg = Params.msg_get params in
      let callback = Params.callback_get params in
      release_params ();
      match callback with
      | None -> Service.fail "No callback parameter!"
      | Some callback ->
        Lwt.async (fun () -> notify callback msg);
        Service.return_empty ()
```

Note that all parameters in Cap'n Proto are optional, so we have to check for `callback` not being set
(data parameters such as `msg` get a default value from the schema, which is
`""` for strings if not set explicitly).

`notify callback msg` just sends a few messages to `callback` in a loop, and then releases it:

```ocaml
let notify callback msg =
  let rec loop = function
    | 0 -> Capability.dec_ref callback; Lwt.return_unit
    | i ->
      Callback.log callback msg >>= function
      | Error ex ->
        Fmt.epr "Callback failed: %a@." Capnp_rpc.Error.pp ex;
        loop 0
      | Ok () ->
        Lwt_unix.sleep 1.0 >>= fun () ->
        loop (i - 1)
  in
  loop 3
```

Exercise: implement `Callback.log` (hint: it's very similar to `Client.ping`, but use `Capability.call_for_unit` because we don't care about the value of the result and we want to handle errors manually)

To write the client for `Echo.heartbeat`, we take a user-provided callback object
and put it into the request:

```ocaml
  let heartbeat t msg callback =
    let open Echo.Heartbeat in
    let request, params = Capability.Request.create Params.init_pointer in
    Params.msg_set params msg;
    Params.callback_set params (Some callback);
    Capability.call_for_unit_exn t method_id request
```

`Capability.call_for_unit_exn` is a convenience wrapper around
`Callback.call_for_value_exn` that discards the result.

In `main.ml`, we can now wrap a regular OCaml function as the callback:

```ocaml
open Lwt.Infix
open Capnp_rpc_lwt

let callback_fn msg =
  Fmt.pr "Callback got %S@." msg

let run_client service =
  let callback = Echo.Callback.service callback_fn in
  Echo.Client.heartbeat service "foo" callback >>= fun () ->
  Capability.dec_ref callback;
  fst (Lwt.wait ())

let () =
  Lwt_main.run begin
    let service = Echo.service in
    run_client service
  end
```

Exercise: implement `Callback.service fn` (hint: it's similar to the original `ping` service, but pass the message to `fn` and return with `Service.return_empty ()`)

And testing it should give (three times, at one second intervals):

```
$ ./main
Callback got "foo"
Callback got "foo"
Callback got "foo"
```

Note that the client gives the echo service permission to call its callback service by sending a message containing the callback to the service.
No other access control updates are needed.

Note also a design choice here in the API: we could have made the `Echo.Client.heartbeat` function take an OCaml callback and wrap it, but instead we chose to take a service and make `main.ml` do the wrapping.
The advantage to doing it this way is that `main.ml` may one day want to pass a remote callback, as we'll see later.

This still isn't very exciting, because we just stored an OCaml object pointer in a message and then pulled it out again.
However, we can use the same code with the echo client and service in separate processes, commmunicating over the network...

### Networking

Let's put a network connection between the client and the server.
Here's the new `main.ml`:

```ocaml
open Lwt.Infix
open Capnp_rpc_lwt

let callback_fn msg =
  Fmt.pr "Callback got %S@." msg

let run_client service =
  let callback = Echo.Callback.service callback_fn in
  Echo.Client.heartbeat service "foo" callback >>= fun () ->
  Capability.dec_ref callback;
  fst (Lwt.wait ())

let socket_path = `Unix "/tmp/demo.socket"

let () =
  let server_thread = Capnp_rpc_unix.serve ~offer:Echo.service socket_path in
  let service = Capnp_rpc_unix.connect socket_path in
  Lwt_main.run @@ Lwt.pick [
    server_thread;
    run_client service;
  ]
```

`Capnp_rpc_unix.serve` creates the named socket in the filesystem and waits for incoming connections.
Each client can access its "bootstrap" service, `Echo.service`.

`Capnp_rpc_unix.connect` connects to the server socket and returns (a promise for) its bootstrap service.

For a real system you'd put the client and server parts in separate binaries.
See the `test-bin/calc.ml` example file for how to do that.

### Pipelining

Let's say the server also offers a logging service, which the client can get from the bootstrap service:

```capnp
interface Echo {
  ping      @0 (msg :Text) -> (reply :Text);
  heartbeat @1 (msg :Text, callback :Callback) -> ();
  logger    @2 () -> (callback :Callback);
}
```

The implementation of the new method in the service is simple -
we export the callback in the response in the same way we previously exported the client's callback in the request:

```ocaml
    method logger_impl _ release_params =
      let open Echo.Logger in
      release_params ();
      let response, results = Service.Response.create Results.init_pointer in
      Results.callback_set results (Some service_logger);
      Service.return response
```

Exercise: create a `service_logger` that prints out whatever it gets (hint: use `Callback.service`)

The client side is more interesting:

```ocaml
  let logger t =
    let open Echo.Logger in
    let request = Capability.Request.create_no_args () in
    Capability.call_for_caps t method_id request Results.callback_get_pipelined
```

We could have used `call_and_wait` here
(which is similar to `call_for_value` but doesn't automatically discard any capabilities in the result).
However, that would mean waiting for the response to be sent back to us over the network before we could use it.
Instead, we use `callback_get_pipelined` to get a promise for the capability from the promise of the `logger` call's result.

Note: the last argument to `call_for_caps` is a function for extracting the capabilities from the promised result.
In the common case where you just want one and it's in the root result struct, you can just pass the accessor directly,
as shown.
Doing it this way allows `call_for_caps` to release any unused capabilities in the result automatically for us.

We can test it as follows:

```ocaml
let run_client service =
  let logger = Echo.Client.logger service in
  Echo.Callback.log logger "Message from client" >|= function
  | Ok () -> ()
  | Error err -> Fmt.epr "Server's logger failed: %a" Capnp_rpc.Error.pp err
```

This should print something like:

```
Service logger: Message from client
```

In this case, we didn't wait for the `logger` call to return before using the logger.
The RPC library pipelined the `log` call directly to the promised logger from its previous question.
On the wire, the messages looks like "Please call the object returned in answer to my previous question".

Now, let's say we'd like the server to send heartbeats to itself:

```ocaml
let run_client service =
  let callback = Echo.Client.logger service in
  Echo.Client.heartbeat service "foo" callback >>= fun () ->
  Capability.dec_ref callback;
  fst (Lwt.wait ())
```

Here, we ask the server for its logger and then (without waiting for the reply), tell it to send heartbeat messages to the promised logger.

Previously, when we exported our local `callback` object, it arrived at the service as a proxy that sent messages back to the client over the network.
But when we send the (promise of the) server's own logger back to it, the RPC system detects this and "shortens" the path;
the capability reference that the `heartbeat` handler gets is a direct reference to its own logger, which
it can call without using the network.

For full details of the API, see the comments in `capnp-rpc-lwt/capnp_rpc_lwt.mli`.


### Contributing

#### Testing

Running `make test` will run through the tests in `test-lwt/test.ml`, which run some in-process examples.

The calculator example can also be run across two Unix processes:

1. Start the server:
   `./_build/default/test-bin/calc.bc serve unix:/tmp/calc.socket`

2. In another terminal, run the client:
   `./_build/default/test-bin/calc.bc connect unix:/tmp/calc.socket`


#### Fuzzing

Running `make fuzz` will run the AFL fuzz tester. You will need to use a version of the OCaml compiler with AFL support (e.g. `opam sw 4.04.0+afl`).

The fuzzing code is in the `fuzz` directory.
The tests set up some vats in a single process and then have them perform operations based on input from the fuzzer.
At each step it selects one vat and performs a random (fuzzer-chosen) operation out of:

1. Request a bootstrap capability from a random peer.
2. Handle one message on an incoming queue.
3. Call a random capability, passing randomly-selected capabilities as arguments.
4. Finish a random question.
5. Release a random capability.
6. Add a capability to a new local service.
7. Answer a random question, passing random-selected capability as the response.

The content of each call is a (mutable) record with counters for messages sent and received on the capability reference used.
This is used to check that messages arrive in the expected order.

The tests also set up a shadow reference graph, which is like the regular object capability reference graph except that references between vats are just regular OCaml pointers (this is only possible because all the tests run in a single process, of course).
When a message arrives, the tests compare the service that the CapTP network handler selected as the target with the expected target in this simpler shadow network.
This should ensure that messages always arrive at the correct target.

In future, more properties should be tested (e.g. forked references, that messages always eventually arrive when there are no cycles, etc).
We should also test with some malicious vats (that don't follow the protocol correctly).

[schema]: https://capnproto.org/language.html
[capnp-ocaml]: https://github.com/pelzlpj/capnp-ocaml
[Cap'n Proto]: https://capnproto.org/
[Cap'n Proto RPC Protocol]: https://capnproto.org/rpc.html
[E-Order]: http://erights.org/elib/concurrency/partial-order.html
