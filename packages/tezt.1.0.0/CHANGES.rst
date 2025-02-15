This file lists the changes added to each version of tezos-node,
tezos-client, and the other Tezos binaries. The changes to the Tezos
protocol are documented in the ``docs/protocols/`` directory; in
particular in ``docs/protocols/alpha.rst``.

Development Version
===================

When you make a commit on master, you can add an item in one of the
following subsections (node, client, …) to document your commit or the
set of related commits. This will ensure that this change is not
forgotten in the final changelog. By having your commits update this
file you also make it easy to find the commits which are related to your
changes using ``git blame``.

Only describe changes which affect users (bug fixes and new features),
not refactorings or tests. Changes to the documentation do not need to
be documented here either.

Node
----

Client
------

Baker / Endorser / Accuser
--------------------------

Proxy server
------------

Protocol Compiler And Environment
---------------------------------

Codec
-----

Docker Images
-------------

Miscellaneous
-------------

Version 10.0~rc1
================

Node
----

-  Replaced the chain storage layer with a more efficient backend in
   terms of both performance and storage size.

-  Added an upgrade procedure to upgrade from the previous store to the
   new one. The procedure is implemented through the
   ``tezos-node upgrade storage`` command. This command is
   non-destructive: the previous store is preserved at
   ``<data_dir>/lmdb_store_to_be_removed`` and needs to be manually
   removed when the user made sure the upgrade process went well.

-  Reworked the storage snapshots:

   -  Introduced a new snapshot format (v2)
   -  Improved the snapshot export/import process in both terms of
      duration and memory usage
   -  Added ``--export-format`` option:

      -  ``--export-format tar`` (default) creates a snapshot as a
         portable tar archive
      -  ``--export-format raw`` creates a snapshot as a raw directory
         suitable for IPFS sharing

   -  The argument ``[output_file]`` in
      ``tezos-node export snapshot [output_file]`` becomes optional and
      defaults to a file whose name follows this pattern
      ``<NETWORK>-<BLOCK_HASH>-<BLOCK_LEVEL>.<SNAPSHOT_HISTORY_MODE>``
   -  Improved the metadata of snasphots which can be displayed using
      ``tezos-node snapshot info``
   -  The ``tezos-node snapshot import`` command is retro-compatible
      with the previous snapshot format (v1) but legacy snapshots cannot
      be exported anymore

-  Interrupted context reconstruction can now be resumed.

-  Promoted the ``experimental-rolling`` history mode to ``rolling``.
   The node’s option ``--history-mode experimental-rolling`` is now
   deprecated and is equivalent to ``--history-mode rolling``.

-  Reworked the nodes rolling and full history modes. Previously, these
   two modes were maintaining a window of ``<preserved cycles>`` cycles
   of metadata (``5`` on mainnet). These modes may now be configured to
   keep a larger window of metadata. E.g.
   ``tezos-node run --history-mode full+2`` will maintain 2 extra cycles
   of metadata, in addition to the network’s preserved cycles. This may
   become useful for users that want to keep more data from the past:
   for instance, to compute rewards payouts. The default number of extra
   preserved cycles is 5 (``5 + 5`` on mainnet).

-  Updated the behaviour of the history mode field in the node's
   `config.json` configuration file. If the number of additional cycles
   is not explicitly specified, the default value is used. The default
   number of additional cycles to keep is set to 5.

-  Improved the shutdown procedure for external validator process.

-  Added command ``replay`` which takes a list of block levels, hashes
   or aliases, revalidate those blocks in the context of their
   predecessor, and check that the result is the same as what is
   currently stored. This is mostly useful for debugging and
   benchmarking purposes.

-  Reduced the maximum allowed timestamp drift to 5 seconds.

-  The file descriptor sink, which can be used to output node events to
   a file using JSON format, now outputs events with an additional field
   ``"hostname"``. This field can be used to identify the node when
   aggregating events from multiple nodes. Its default value is the
   hostname of the device the node is running on, and it can be
   customized with environment variable ``TEZOS_NODE_HOSTNAME``.

-  Fixed a bug that caused the lack of connection in private network
   with ``--connections`` set to 1.

-  Fixed a potential interleaving of distinct events written to a file
   descriptor sink simultaneously.

-  Introduced Access Control Lists for RPC servers, which allow to
   restrict access to selected RPC endpoints for different listening
   addresses.

-  You can now control the verbosity of the logs of the context
   storage backend using the ``TEZOS_CONTEXT`` environment
   variable. Set it to ``v`` to display log messages with level "info"
   or to ``vv`` to also display log messages with level "debug".

-  The ``TEZOS_STORAGE`` variable now has no effect. Use
   ``TEZOS_CONTEXT`` instead (see previous item).

-  Added an RPC to run `TZIP-4
   views<https://gitlab.com/tzip/tzip/-/blob/master/proposals/tzip-4/tzip-4.md#view-entrypoints>`__
   offchain, accessible via ``../<block_id>/helpers/scripts/run_view``.

Client
------

-  Changed to 5 the recommended number of blocks after which an
   operation can be considered final. Under normal network conditions
   and an attacker with less than 33% of stake, an operation can be
   considered final with quasi-certainty if there are at least 5 blocks
   built on top of it. See Emmy\* TZIP for more detailed explanations.

-  Added ``--mode light`` which makes the client execute some RPCs
   locally (to lower the load of nodes and to avoid having to trust
   the nodes). This mode is akin to light clients and SPV clients:
   it uses Merkle proofs to make the light mode super safe.

-  Added commands to display the hash of Michelson scripts from files and
   from addresses.

-  Added support for a new generic version of the multisig contract.

-  Added a new flag, ``--simulation``, which simulates operations instead of preapplying them.

-  ``hash data`` command now supports the optional ``--for-script [TSV|CSV]``.

-  Rename ``--block`` option of ``sign message`` command to ``--branch``.

-  Commands using an encrypted key now fail after the user fails to give the correct
   password three times.

-  Added support for FA1.2 standard, allowing to interact with fungible
   assets contracts using the ``from fa1.2 contract ...`` commands, and
   support for running the view entrypoints offchain.

Baker / Endorser / Accuser
--------------------------

-  Optimized the performance of the baker to reduce the number of RPC
   calls to the node while waiting for endorsements.

Proxy server
------------

-  Added a new binary: ``tezos-proxy-server``, a read-only frontend to a node.
   It is designed to lower the load of nodes, by being capable
   of serving `protocol RPCs <https://tezos.gitlab.io/alpha/rpc.html>`__.
   An instance of a proxy server is protocol-specific: it automatically picks
   up the protocol from the backing node when it starts. Proxy servers
   can be started and destroyed at will, making them easy to deploy.

   Please refer to the `online documentation <https://tezos.gitlab.io/user/proxy-server.html>`__
   for further details.

Protocol Compiler And Environment
---------------------------------

Codec
-----

Docker Images
-------------

Miscellaneous
-------------

Version 9.3 (Not Available Yet)
===============================

-  Reintroduced the following RPCs in the Granada RPC plugin. These
   RPCs were already present in the Edo and Florence protocol plugin
   and are deprecated, they will be removed in the successor protocol
   of Granada.

   - ``../<block_id>/helpers/scripts/run_code/normalized``
     (deprecated alias of ``../<block_id>/helpers/scripts/run_code``)
   - ``../<block_id>/helpers/scripts/trace_code/normalized``
     (deprecated alias of ``../<block_id>/helpers/scripts/trace_code``)

-  Increased the LMDB store mapsize limit to avoid ``MDB_MAP_FULL`` failures.

Version 9.2
===========

Node
----

-  Added Granada, a protocol proposal for Mainnet featuring, among others,
   the Emmy* consensus algorithm, Liquidity Baking, and reduced gas consumption.

-  Added the configuration for Granadanet, a test network for Granada,
   as a built-in network alias (``--network granadanet``).

-  Updated the mempool to keep more than 50 non-included operations
   when receiving a new block. In particular, this should result in
   fewer endorsements being missed.

Docker Images
-------------

-  File ``scripts/mainnet.sh`` is now deprecated and may be removed starting from
   version 10.0. If you have a script that downloads this file (with
   ``wget https://gitlab.com/tezos/tezos/raw/latest-release/scripts/mainnet.sh``
   for instance), your script should now download ``scripts/tezos-docker-manager.sh``
   instead and rename it into ``mainnet.sh`` (with
   ``wget -O mainnet.sh https://gitlab.com/tezos/tezos/raw/latest-release/scripts/tezos-docker-manager.sh``
   for instance).

-  File ``scripts/carthagenet.sh`` may also be removed starting from version 10.0.

Version 9.1
===========

Node
----

-  Fixed a performance issue that caused the node to freeze for several minutes
   and memory usage to rise to unexpected levels.

-  Reintroduced the following RPCs in the Florence RPC plugin. These
   RPCs were already present in the Edo protocol plugin and were removed
   by mistake when moving the functionality they offer to the Florence
   protocol:

   - ``../<block_id>/context/contracts/<contract_id>/storage/normalized``
   - ``../<block_id>/context/contracts/<contract_id>/script/normalized``
   - ``../<block_id>/context/big_maps/<big_map_id>/<script_expr>/normalized``
   - ``../<block_id>/helpers/scripts/run_code/normalized``
     (deprecated alias of ``../<block_id>/helpers/scripts/run_code``)
   - ``../<block_id>/helpers/scripts/trace_code/normalized``
     (deprecated alias of ``../<block_id>/helpers/scripts/trace_code``)

Version 9.0
===========

Node
----

-  Fixed a bug where the mempool could crash with an assertion failure.

Version 9.0~rc2
===============


Node
----

-  Fixed a performance regression of the storage backend. This in
   particular impacted RPCs that query the context. This regression was
   introduced in 9.0~rc1.

-  Removed protocol ``PsFLorBA``, the variant of Florence with baking
   accounts, which was rejected in favor of ``PsFLoren``.

-  The cap on the number of expected connections that was introduced in
   9.0~rc1 can now be bypassed with ``--disable-config-validation``.

Baker
-----

-  Added the fixes to the baker that were released in 8.3 but that were
   not present in 9.0~rc1 (which was published before 8.3).


Client
------

-  Improved operation injection to better deal with cases where
   parameters (fees, gas limit, …) are partially given by the user.

Version 9.0~rc1
===============


Node
----

-  Added Florence, the current protocol proposal on Mainnet. This is the
   version of Florence without baking accounts (``PsFLoren``).

-  Added a new version of the protocol environment (v2). It is used by
   Florence.

-  Added built-in network configurations for Edo2net (which runs Edo2,
   the current Mainnet protocol) and Florencenet (which runs Florence).
   Their corresponding aliases for ``--network`` are ``edo2net`` and
   ``florencenet``.

-  Capped the number of expected connections to ``100`` on the
   command-line interface.

-  Fixed a bug that caused the execution of the prevalidator when the
   node was not bootstrapped.

-  Enforced loading of non-embedded protocols before starting the node
   to allow the prevalidator to start correctly.

-  Optimized I/O and CPU usage by removing an unnecessary access to the
   context during block validation.

-  Fixed a bug where any event would allocate more memory than needed
   when it was not to be printed.

-  Added a new RPC for Alpha: ``helpers/scripts/normalize_type``.

-  Replace Edonet by Edo2net in built-in network configuration. The
   alias to give to ``--network`` is now ``edo2net``.

-  Removed the built-in configuration for Delphinet. You can no longer
   configure your node with ``--network delphinet``.

-  The ``--network`` option now also accepts the name of a file
   containing the configuration for a custom network, or a URL from
   which such a file can be downloaded.

-  Fixed JSON encoding of timestamps before epoch (1970).
   Pretty-printing and encoding of dates before epoch in human-readable
   form (as part of a JSON value) that failed in the past will now
   succeed. Binary form (used when nodes exchange data) was unaffected
   by the bug. This may impact some RPC representations of timestamps.

-  Some RPCs now send their response in chunked transfer encoding.
   Additionally, the implementation allows for more concurrency
   internally: it allows RPC requests to be treated even if a request is
   currently being treated. This leads to some improved response times
   on some RPC requests.

-  Added a way to optionally specify an expected peer identity for all
   command line options accepting a point as argument (such as
   ``--peer``). This identity can be given using the usual b58 format.
   The RPC ``patch /network/points/<point> {"peer_id": <peer_id>}`` set
   the expected identity and ``get /network/points/<point>`` tells
   whether an expected ``peer_id`` has been set.

-  Added a checking of the well-formedness of addresses in the config
   files when the node starts. If this check fails, the node stops with
   an explanation.

-  Fixed the targeted number of connections which did not respect the
   constraints expressed with –connections settings.

-  RPC: the semantics of ban and unban has changed:

   -  instead of just affecting the banned/unbanned point, they affect
      all associated cryptographic identities;
   -  additionally, ban now removes the cryptographic identity / point
      from the whitelist, which was not previously the case.

-  RPC: the following RPCs are now deprecated:

   -  GET: ``/network/peers/<peer_id>/ban``
   -  GET: ``/network/peers/<peer_id>/unban``
   -  GET: ``/network/peers/<peer_id>/trust``
   -  GET: ``/network/peers/<peer_id>/untrust``
   -  GET: ``/network/points/<point>/ban``
   -  GET: ``/network/points/<point>/unban``
   -  GET: ``/network/points/<point>/trust``
   -  GET: ``/network/points/<point>/untrust``

-  RPC: the following RPCs are added and replace those above:

   -  PATCH: ``/network/peers/<peer_id>`` payload
      ``{ acl: [ban,trust,open] }``
   -  PATCH: ``/network/point/<point>`` payload
      ``{ acl: [ban,trust,open], peer_id: <peer_id> }`` where

      -  ``{acl : ban}``: blacklist the given address/peer and remove it
         from the whitelist if present
      -  ``{acl: trust}``: trust a given address/peer permanently and
         remove it from the blacklist if present.
      -  ``{acl: open}``: removes an address/peer from the blacklist and
         whitelist.

-  Added RPC ``DELETE /network/greylist`` to clear the greylist tables.
   RPC ``GET /network/greylist/clear`` is now deprecated.


Client
------

-  Fixed the return code of errors in the client calls to be non-zero.

-  Added a new multisig command to change keys and threshold:
   ``set threshold of multisig contract ...``.

-  Added a command to perform protocol migrations in persistent mockup
   mode: ``migrate mockup to <protocol_hash>``.

-  Added the ``--version`` flag.

-  Fixed commands ``--mode mockup config show`` and
   ``--mode mockup config init`` which returned the default values
   rather than the actual ones.

-  Replaced command ``check that <bytes> was signed by <pkh>`` by
   ``check that bytes <bytes> were signed by <pkh>`` to differentiate
   from new command ``check that message <string> was signed by <pkh>``.

-  Added wallet support for PVSS keys.

-  Added support for all protocol constants in Mockup mode.

-  Mockup mode now uses Alpha instead of an arbitrary protocol when none
   is specified. It also warns that it takes this default behavior.


Baker / Endorser / Accuser
--------------------------

-  Added the ``--version`` flag.

-  Fixed the operation ordering in the baker so that the most profitable
   operations are applied first.


Protocol Compiler And Environment
---------------------------------

-  Added the ``--version`` flag.


Codec
-----

-  Added the ``--version`` flag.

-  Added support for some base encodings including arbitrary precision
   integers, n-bit sized integers, and floating point numbers.


Miscellaneous
-------------

-  Sapling: fixed dummy address generator (the last 5 bits are now
   correctly set to 0 instead of the first 5 bits).

-  Fixed a bug that caused some file descriptors to be leaked to
   external processes.

Version 8.3
===========


Baker / Endorser / Accuser
--------------------------

-  Fixed a bug where the baker would not consider all of the operations
   when a costly one was encountered.

-  Fixed a bug where the most profitable operations would not be applied
   first.

Version 8.2
===========


Node
----

-  Override ``PtEdoTez`` activation by ``PtEdo2Zk`` in mainnet network.

-  Make size limits on p2p messages explicit in low-level encodings.

-  Add new RPCs for Edo:
   ``helpers/scripts/normalize_{data,script,type}`` and a
   ``XXX/normalized`` variant to each protocol RPC ``XXX`` outputting
   Michelson expressions.


Baker / Endorser / Accuser
--------------------------

-  Replace ``PtEdoTez`` by ``PtEdo2Zk``.


Miscellaneous
-------------

-  Update external opam dependencies. In particular, switch to
   ``hacl-star.0.3.0-1`` which performs better.

Version 8.1
===========


Node
----

-  Fix a performance regression affecting serialization of tz3
   signatures by reverting the P256 implementation to ``uecc``.

-  Fixup allowing nodes in ``--history-mode full`` to answer to all new
   messages to the distributed database protocol.


Client
------

-  As a consequence of moving back to ``uecc``, revert for now the
   ability to sign with tz3 addresses.


Miscellaneous
-------------

-  Allow building from sources with older version of git (used to
   require 2.18)

-  Downgrade ``mirage-crypto`` dependency to avoid failure on startup
   with ``illegal instruction`` on some hardware.

Version 8.0
===========


Node
----

-  Added two new bootstrap peers for Mainnet and one for Edonet.

-  Fixes a bug where any event would allocate more memory than needed
   when it were not to be printed.

-  Improved how the node stores buffered messages from peers to consume
   less memory.

-  Enforce loading of non-embedded protocols before starting the node
   allowing the prevalidator to start correctly.

-  Optimized the I/O and CPU usage by removing an unnecessary access to
   the context during block validation.


Docker Images
-------------

-  Bump up base image to ``alpine:12``. In particular, it changes rust
   and python versions to 1.44.0 and 3.8.5 respectively.


Miscellaneous
-------------

-  Recommend rust version 1.44.0 instead of 1.39.0.

Version 8.0~rc2
===============


Node
----

-  Snapshots exported by a node using version 8 cannot be imported by a
   node running version 7. This is because the new snapshots contain
   additional information required by protocol Edo. On the other hand,
   snapshots exported by a node using version 7 can be imported by a
   node running version 8.

-  Added a new version (version 1) of the protocol environment. The
   environment is the set of functions and types that the economic
   protocol can use. Protocols up to Delphi used environment version 0.
   The Edo protocol uses environment version 1.

-  Added the Edo protocol: the node, client and codec now comes linked
   with Edo, and the Edo daemons (baker, endorser and accuser) are
   available.

-  Added a built-in configuration for Edonet, a test network that runs
   Edo. You can configure your node to use this test network with
   ``--network edonet``.

-  Removed the built-in configuration for Carthagenet, which ends its
   life on December 12th 2020. You can no longer configure your node
   with ``--network carthagenet``.

-  The bootstrap pipeline no longer tries to concurrently download steps
   from other peers. The result is actually a more efficient bootstrap,
   because those concurrent downloads resulted in multiple attempts to
   download the same block headers. It also resulted in more memory
   usage than necessary.

-  Added six messages to the distributed database protocol and bumped
   its version from 0 to 1. These new messages allow to request for: a
   peer’s checkpoint, the branch of a given protocol and a block’s
   predecessor for a given offset. These messages are not yet used but
   will be useful for future optimizations.

-  You can now specify the data directory using environment variable
   ``TEZOS_NODE_DIR``. If you both set this environment variable and
   specify ``--data-dir``, the latter will be used.

-  Added new RPC ``/config`` to query the configuration of a node.

-  Changed signal handling and exit codes for most binaries. The codes’
   significance are detailed in `the user
   documentation <http://tezos.gitlab.io/user/various.html#tezos_binaries_signals_and_exit_codes>`__.

-  Command ``tezos-node --version`` now exits with exit code 0 instead
   of 1.

-  Fixed the synchronisation threshold which was wrongly capped with an
   upper bound of 2 instead of a lower bound of 2 when ``--connections``
   was explicitely specified while the synchronisation threshold itself
   was not specified.


Client
------

-  Added client command ``import keys from mnemonic``, which allows to
   import a key from a mnemonic following the BIP39 standard.

-  When the client asks for a password, it no longer tries to hide its
   input if the client was not run from a terminal, which allows for use
   in a script.

-  You can now specify the base directory using environment variable
   ``TEZOS_CLIENT_DIR``. If you both set this environment variable and
   specify ``--base-dir``, the latter will be used.

-  Fixed command ``set delegate for <SRC> to <DLGT>`` to accept public
   key hashes for the ``<DLGT>`` field.

-  Fixed the ``rpc`` command that did not use the full path of the URL
   provided to ``--endpoint``. Before this,
   ``--endpoint http://localhost:8732/node/rpc`` would have been
   equivalent to ``--endpoint http://localhost:8732``.

-  Fixed an issue where the client would try to sign with a key for
   which the private counterpart was unknown even though a remote signer
   was connected.


Baker / Endorser / Accuser
--------------------------

-  Fixed a crash (assertion error) that could happen at exit, in
   particular if a baker were connected.


Docker Images
-------------

-  Docker images are now available for arm64. Image tags stay the same
   but now refer to “multi-arch” manifests.

Version 8.0~rc1
===============


Node
----

-  Fixed some cases where the node would not stop when interrupted with
   Ctrl+C.

-  The node’s mempool relies on a new synchronisation heuristic. The
   node’s behaviour, especially at startup, may differ slightly; log
   messages in particular are likely to be different. More information
   is available in the whitedoc.

-  The new synchronisation heuristic emits an event when the
   synchronisation status changes. This can be used to detect when the
   chain is stuck for example. More information is available in the
   whitedoc.

-  Node option ``--bootstrap-threshold`` is now deprecated and may be
   removed starting from version 9.0. Use
   ``--synchronisation-threshold`` instead.

-  Fixed an issue which prevented using ports higher than 32767 in the
   client configuration file.

-  The ``tezos-node run`` command now automatically generates an
   identity file as if you had run ``tezos-node identity generate`` if
   its data directory contains no identity file.

-  Improved various log messages and errors.

-  When bootstrapping, do not greylist peers in rolling mode whose
   oldest known block is newer than our head.

-  Made the timestamp in log messages more precise (added milliseconds).

-  Fixed encoding of P2P header message length for larger lengths.

-  Added ``-d`` as a short-hand for the ``--data-dir`` option of the
   node.

-  Added a built-in activator key for the built-in sandbox network. This
   allows to spawn a sandbox without the need for a custom genesis
   protocol.

-  Greylist the identity and address of peers that send malformed
   messages.

-  Fixed some cases where the context was not closed properly when
   terminating a node or if the baker failed to bake a block.

-  Removed the “get operation hashes” and “operation hashes” messages of
   the distributed database protocol. Those messages were never used.

-  Reduced the amount of log messages being kept in memory (that can be
   queried using RPCs) before they are discarded to reduce the total
   memory footprint.

-  Fixed a case where the ``/workers/prevalidator`` RPC could fail if
   there were too many workers.

-  Fixed how protocol errors are displayed. Before, there were printed
   using the cryptic ``consequence of bad union`` message.

-  Pruned blocks can now be queried using RPC
   ``/chains/<chain>/blocks/<block>``. The ``metadata`` field will be
   empty in the response, leaving only the header.

-  Fixed handling of pre-epoch timestamps, in particular in RPCs.

-  Time is now output with millisecond precision when calling RPCs.

-  Fixed the ``/chains/<chain>/blocks`` RPC which sometimes did not
   return all blocks.

-  Improved the performance of the progress indicator when importing
   snapshots.

-  Improved performance of ``tezos-node snapshot export``.

-  Fixed the node which sent too many “get current branch” messages to
   its peers on testchain activation.


Client
------

-  The ``tezos-client config show`` command now takes into account the
   command line arguments.

-  Fixed an issue which caused ``tezos-client rpc get /errors`` as well
   as ``tezos-codec dump encodings`` to fail because of duplicate
   encodings. As a result, some protocol encodings whose name was not
   prefixed by the protocol name are now prefixed by it. If you have
   tools which rely on encoding names you may have to update them.

-  Added client command
   ``multiple transfers from <src> using <transfers.json>`` to perform
   multiple operations from the same address in a single command.

-  Added option ``--endpoint`` to client and bakers. It replaces options
   ``--addr``, ``--port`` and ``--tls`` which are now deprecated.

-  Added command ``rpc patch`` to the client, to perform RPCs using the
   PATCH HTTP method.

-  Make the client emit a more human-readable error if it failed to
   understand an error from the node.

-  Added client commands
   ``tezos-client convert script <script> from <input> to <output>`` and
   ``tezos-client convert data <data> from <input> to <output>`` to
   convert to and from michelson, JSON, binary and OCaml with
   type-checking.

-  The client now retries commands a few times if the node is not yet
   ready.

-  Added client command ``compute chain id from block hash <hash>`` and
   ``compute chain id from seed <seed>`` to compute the chain id
   corresponding to, respectively, a block hash or a seed.

-  Added the verbose-signing switch to a number of multisig commands.

-  The ``prepare multisig`` commands now display the Blake 2B hash.

-  Some client commands which use the default zero key
   ``tz1Ke2h7sDdakHJQh8WX4Z372du1KChsksyU`` in dry runs now display this
   key using an informative string
   ``the baker who will include this operation`` instead of the key
   itself.

-  Fixed an error which occurred in the client when several keys had the
   same alias.

-  Added support for some ``rpc {get,post,...}`` commands in the
   client’s mockup mode.

-  Added ``--mode mockup`` flag to ``config init`` for the client’s
   mockup mode, that writes the mockup’s current configuration to files.

-  Added ``--mode mockup`` flag to ``config show`` for the client’s
   mockup mode, that prints the mockup’s current configuration to
   standard output.

-  Added arguments ``--bootstrap-accounts`` and ``--protocol-constants``
   to the client’s ``create mockup`` command. ``--bootstrap-accounts``
   allows changing the client’s bootstrap accounts and
   ``--protocol-constants`` allows overriding some of the protocol’s
   constants. Use commands ``config {show,init} mockup`` (on an existing
   mockup) to see the expected format of these arguments.

-  The client no longer creates the base directory by default in mockup
   mode.

-  Fixed the argument ``--password-filename`` option which was ignored
   if it was present in the configuration file.


Baker / Endorser / Accuser
--------------------------

-  The baker now automatically tries to bake again in case it failed. It
   retries at most 5 times.

-  The baker now outputs an explicit error when it loses connection with
   the node.

-  Added command-line option ``--keep-alive`` for the baker. It causes
   the baker to attempt to reconnect automatically if it loses
   connection with the node.


Protocol Compiler And Environment
---------------------------------

-  Prepare the addition of SHA-3 and Keccak-256 cryptographic
   primitives.

-  Prepare the introduction of the new protocol environment for protocol
   008.

-  The protocol compiler now rejects protocols for which the OCaml
   compiler emits warnings.


Codec
-----

-  Fixed ``tezos-codec dump encodings`` which failed due to two
   encodings having the same name.

Version 7.5
===========


Client
------

-  Fixed gas cost estimation for Delphi for contract origination and
   revelation.


Codec
-----

-  Fixed the name of the ``big_map_diff`` encoding from
   ``<protocol_name>`` to ``<protocol_name>.contract.big_map_diff``.

Version 7.4
===========

-  Added the Delphi protocol.

-  Added the Delphinet built-in network configuration. The alias to give
   to ``--network`` is ``delphinet``.

-  Updated the list of bootstrap peers for Carthagenet.

Version 7.3
===========

-  Fixed a case where the number of open file descriptors was not
   correctly limited. This could result in the node crashing due to
   being out of file descriptors.

-  Set a limit to the length of some incoming messages which previously
   did not have one.

-  Fixed some value encodings which were missing cases.

Version 7.2
===========

-  Fixed an error that could cause baking to fail when validating some
   smart contracts.

-  Fixed an issue in ``tezos-docker-manager.sh`` which prevented to use
   some options, such as ``--rpc-port``.

Version 7.1
===========

Source Compilation
------------------

-  The ``Makefile`` now ignores directories with no
   ``lib_protocol/TEZOS_PROTOCOL`` files when listing protocols to
   compile. This fixes an error where ``make`` complained that it had no
   rule to build ``TEZOS_PROTOCOL`` for directories that Git does not
   completely remove when switching branches.

-  One can now use opam 2.0.0 again. In version 7.0, an error saying
   that it did not know about option ``--silent`` was emitted.

-  The repository no longer contains file names which are longer than
   140 characters. Longer file names prevented users from checking out
   version 7.0 on encrypted file systems in particular.

-  Fixed an issue causing ``make build-deps`` to sometimes fail after an
   update of the digestif external library.


Client
------

-  Optimized the LAMBDA which is built when injecting manager
   operations.

-  Fixed a bug which caused the wrong entrypoint (``set_delegate``
   instead of ``remove_delegate``) from being used in some cases when
   setting delegates.

-  Command ``activate account ... with`` can now be given a JSON value
   directly as an argument instead of only a filename.

-  Syntax for command ``call from <SRC> to <DST>`` has been fixed to
   match the one for ``proto_alpha``. It should now be called as
   ``call <DST> from <SRC>``.

Version 7.0
===========

Multinetwork
------------

-  Node and client now come with all current and past protocols that are
   still in use on Mainnet or some active test networks.

-  Added option ``--network`` to ``tezos-node config init`` to select
   which network to connect to from a list of built-in networks (e.g.
   ``carthagenet``). If you do not run ``config init`` or run it without
   the ``--network`` option, the node will use the default network
   (Mainnet).

-  Added option ``--network`` to ``tezos-node run`` and
   ``tezos-node snapshot import`` which causes the node to check that it
   is configured to use the given network.

-  Added ``network`` configuration field to select which network to
   connect to, similar to ``--network``. This field also lets you
   specify an entirely custom, non-built-in network and is especially
   useful to run private networks. For instance, LabNet
   (https://forum.tezosagora.org/t/introducing-labnet-a-rapid-iteration-testnet-for-tezos/1522)
   uses such a custom configuration.

-  The ``network`` configuration field also allows to specify
   user-activated upgrades and user-activated protocol overrides. In the
   past, those upgrades and overrides required you to upgrade the node;
   now, you can just edit the configuration file instead. You can also
   disable built-in upgrades by specifying the configuration explicitly.

-  The ``network`` configuration field also allows to specify the
   parameters of the genesis protocol, such as the activation key of
   ``proto_genesis``. This allows to use the same genesis protocol for
   several test networks with different activation keys.

-  The network name is printed in the logs on startup.

For more information, see: http://tezos.gitlab.io/user/multinetwork.html


Node
----

-  Added RPC ``/version`` which returns the version of the node, the
   version of the P2P protocol, the version of the distributed DB, the
   commit hash and the commit date. Other RPCs which returned version
   numbers (``/network/version``, ``/network/versions`` and
   ``/monitor/commit_hash``) are deprecated: use ``/version`` instead.

-  RPCs which returned ``treated`` and ``completed`` fields now return
   durations (relative to the value of the ``pushed`` field) instead of
   timestamps.

-  Improved various log messages and errors.

-  Fixed a memory leak causing greylisted addresses to be stored several
   times unnecessarily.

-  Fixed a small memory leak causing each new worker to store a logger
   section name forever.

-  When exporting snapshots, you can now specify the block not only by
   its hash but also by its level or using an alias such as:
   ``caboose``, ``checkpoint``, ``save_point`` or ``head``.

-  Fixed a bug which caused snapshots to fail if the checkpoint was a
   protocol transition block.

-  Added ``--status`` flag to ``upgrade storage``. This flag causes the
   node to tell you whether a storage upgrade is available.

-  Allow more files to exist in the data directory when starting a node
   from an empty storage: ``version.json``, ``identity.json``,
   ``config.json`` and ``peers.json``. Before, only ``identity.json``
   was allowed.

-  Fixed a bug which caused the check of the ``version.json`` file to be
   performed incorrectly.

-  The external validator process now dynamically loads the new protocol
   after a protocol upgrade.

-  Sandbox mode may now be used with the external validator process.
   Before, it required ``--singleprocess``.

-  The mempool RPC for preapplication now actually sorts operations when
   the flag is set.

-  Changed the format of the peer-to-peer protocol version number. Nodes
   which are running a version older than Mainnet December 2019 can no
   longer connect to nodes running this new version and should upgrade.

-  Added new peer-to-peer message type: Nack, that carries a list of
   alternative peers and can be returned by nodes with no room for your
   connection.

-  If maximum number of connections has been reached, before rejecting
   peers, authenticate them and memorize their point information.

-  Improved the behavior of the greylist of peers.

-  The node is now capable of recovering from some cases of storage
   corruption that could in particular occur if the disk became full or
   if the node was killed.

-  Fixed a bug which caused the peer-to-peer layer to send the wrong
   acknowledgement message in response to swap requests.

-  Nodes built for Docker images should now correctly contain the
   version number.

-  Removed non-read-only Babylon client commands as they are no longer
   useful.

-  If the node connects to a peer of another network (e.g. if a Mainnet
   node connects to a Carthagenet node), it now removes this peer from
   its list of known peers. This in particular means that it will no
   longer advertize this peer or try to connect to it again.

-  In private mode, do not try to discover the local network peers as
   they will not be trusted anyway.

-  Fixed a bug which caused the node to stop with a segmentation fault.


Client
------

-  Added protocol command ``expand macros in`` to expand macros in
   Michelson code.

-  Added command ``tezos-admin-client protocol environment`` which
   displays the version of the environment used by a given protocol.

-  Greatly reduce the time the client takes to load.

-  Added option ``--mode mockup`` which can be used to run client
   commands, such as commands to typecheck Michelson code, without a
   running node.

-  Added commands ``create mockup for protocol`` and
   ``list mockup protocols`` to manage mockup environments used by
   ``--mode mockup``.

-  Multisig commands can now be used both with contract aliases and
   addresses instead of only with aliases.

-  Added a timeout to signature operations using a remote signer, which
   could otherwise block the baker, endorser or accuser.

Protocol
--------

-  Added safety checks against code injection when compiling downloaded
   or injected protocols. This was mostly a security concern for nodes
   with publicly available RPCs.

-  Added new demo protocol: ``proto_demo_counter``.

-  Prepared the shell to be able to handle multiple protocol environment
   versions.

Docker Script
-------------

-  Renamed script ``alphanet.sh`` into ``tezos-docker-manager.sh``. You
   should still use ``mainnet.sh`` and ``carthagenet.sh`` as they are
   now symbolic links to ``tezos-docker-manager.sh`` instead of
   ``alphanet.sh``.

-  Removed script ``zeronet.sh`` as Zeronet is using an older version of
   Babylon (PsBABY5H) for which the baker, endorser and accuser binaries
   are no longer available. If you need to connect to Zeronet, use the
   ``zeronet`` branch instead, which still has the ``zeronet.sh``
   script.


Miscellaneous
-------------

-  Remove outdated nginx.conf.
