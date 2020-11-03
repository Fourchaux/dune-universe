# :candy: Caramel
> An Erlang backend to the OCaml compiler

## What is Caramel?

Caramel is an **experimental project**, featuring primarily an Erlang backend
to the OCaml compiler, that brings one of the most mature and expressive
type-systems in the world to the BEAM.

In short, it lets you write some OCaml:

```ocaml
(* math.ml *)
let inc x = x + 1
```

and it will compile it to Erlang.

```erlang
% math.erl
-module(math).
-export([inc/1]).
inc(X) -> erlang:'+'(X, 1).
```

> NOTE: idiomatic support for infix operators is still not there :)

Read more about the current and future goals in [the roadmap](./ROADMAP.md).

## Getting started

You can download the latest pre-release from the [releases
page](https://github.com/AbstractMachinesLab/caramel/releases). After
unpacking it you should be able to add it to your PATH env and start playing
around with the `caramelc` binary.

Like this:

```sh
# in this example I'm running linux with glibc
$ wget https://github.com/AbstractMachinesLab/caramel/releases/download/v0.0.12/caramel-v0.0.12-x86_64-unknown-linux-gnu.tar.gz
$ tar xzf caramel-*
$ export PATH=$(pwd)/caramel/bin
```

Now we can do a quick test:

```sh
$ echo 'let hello () = "world"' > hello_world.ml
$ caramelc compile hello_world.ml
Compiling hello_world.erl       OK
$ erl
Erlang/OTP 23 [erts-11.0.3] [source] [64-bit] [smp:64:64] [ds:64:64:10] [async-threads:1] [hipe]

Eshell V11.0.3  (abort with ^G)
1> c(hello_world).
{ok,hello_world}
2> hello_world:hello().
<<"world">>
```

To make use of the entire standard library you'll have to run `erlc` to compile it:

```sh
# after unzipping
$ erlc ./caramel/lib/caramel/stdlib/beam/*.erl
$ erl -pa ./caramel/lib/stdlib/beam
Erlang/OTP 23 [erts-11.0.3] [source] [64-bit] [smp:64:64] [ds:64:64:10] [async-threads:1] [hipe]

Eshell V11.0.3  (abort with ^G)
1> caramel_runtime:binary_concat(<<"hello, ">>, <<"world!">>).
<<"hello, world!">>
```

## Examples

You can find several examples in [`./examples`](./examples), and in
[`./tests/compiler`](./tests/compiler/).

In the examples, you can run `caramelc compile *.ml` to get them all built in
the right order.

Here's an OCaml module and the compiled Erlang module:

```ocaml
type msg = [ `Reset | `Add of int | `Hello of string ]

type state = string * int

let handle_message : state -> msg option -> state =
 fun state msg ->
  let x, y = state in
  match msg with
  | Some `Reset -> ("", 0)
  | Some (`Add z) -> (x, z)
  | Some (`Hello n) -> (n, y)
  | None -> state

let rec loop ~recv state =
  Io.format "current_state: ~p\n" [ state ];
  let msg = recv ~timeout:(Process.Bounded 5000) in
  let state2 = handle_message state msg in
  loop ~recv state2

let start x = Process.make (fun _self recv -> loop ~recv x)

let do_work () =
  let pid = start ("hi", 0) in
  Erlang.send pid (`Hello "joe")
```

```erlang
% Source code generated with Caramel.
-module(holder_annotated).
-export_type([msg/0]).
-export_type([state/0]).

-export([do_work/0]).
-export([handle_message/2]).
-export([loop/2]).
-export([start/1]).

-type msg() :: reset
             | {add, integer()}
             | {hello, binary()}
             .

-type state() :: {binary(), integer()}.

-spec handle_message(state(), option:t(msg())) -> state().
handle_message(State, Msg) ->
  {X, Y} = State,
  case Msg of
    {some, reset} -> {<<"">>, 0};
    {some, {add, Z}} -> {X, Z};
    {some, {hello, N}} -> {N, Y};
    none -> State
  end.

-spec loop(fun((process:after_time()) -> option:t(msg())), state()) -> ok.
loop(Recv, State) ->
  io:format(<<"current_state: ~p\n">>, [State | []]),
  Msg = Recv({bounded, 5000}),
  State2 = handle_message(State, Msg),
  loop(Recv, State2).

-spec start(state()) -> erlang:pid(msg()).
start(X) -> process:make(fun
  (_self, Recv) -> loop(Recv, X)
end).

-spec do_work() -> ok.
do_work() ->
  Pid = start({<<"hi">>, 0}),
  erlang:send(Pid, {hello, <<"joe">>}).
```

Running on the Erlang shell we get this output:

```erlang
examples/processes λ erl
Erlang/OTP 23 [erts-11.0.3] [source] [64-bit] [smp:64:64] [ds:64:64:10] [async-threads:1] [hipe]

Eshell V11.0.3  (abort with ^G)
1> c(holder_annotated).
{ok,holder_annotated}
2> holder_annotated:
do_work/0         handle_message/2  loop/2            module_info/0
module_info/1     start/1
2> holder_annotated:do_work().
current_state: {<<"hi">>,0}
{hello,<<"joe">>}
current_state: {<<"joe">>,0}
current_state: {<<"joe">>,0}
3>
BREAK: (a)bort (A)bort with dump (c)ontinue (p)roc info (i)nfo
       (l)oaded (v)ersion (k)ill (D)b-tables (d)istribution
```
