# Change Log

## [0.10.1] - 2018-02-27

- Fix a pool size counting bug when resource allocation fails.  This can
  cause deadlock due to pool exhaustion.

## [0.10.0] - 2018-02-14

- Added `-linkall` flags to driver libraries to fix direct linking (#9).
- Added convenience functions `collect_list` and `rev_collect_list` (#8).
- Renamed `template` to `query` and related function, leaving deprecated
  aliases.
- Added `ptime_span` field type mapping to SQL intervals.
- Be more permissive about types of data returned from MariaDB when
  expecting numerical results.

## [0.9.0] - 2018-01-04

- Move v1 into findlib sublibraries and announce deprecation.
- Port remaining tests to v2 and fix issues in MariaDB and Sqlite3 drivers.
- Don't include password component of URIs in error messages.
- Rename `io` type constructor to `future`.
- Fix pool size limit enforcement.
- Drop error on disconnect.
- Support substitutions in request convenience functions.

## [0.8.1] - 2017-12-06

- Fix `start` transaction for PostgreSQL v2.
- Fix dependency on ptime in `caqti.opam` in distribution.

## [0.8.0] - 2017-12-04

- Remove most deprecations.
- Add new v2 API.
- Move away most of the v1 API, but keep deprecated aliases for the client
  API.

The main difference of the new API compared to the old is:

- It uses typed parameters and rows with an extensible variant for field
  type and a custom definable compound type.
- The connection has a `call` method which gives access to a result object
  before iterating over the returned rows.
- Error handling is done with the `result` type, using a collection of error
  types formed as polymorphic variants of records.

*Notice:* This version is mostly backwards compatible.  New code should use
v2, but v1 will be kept for now.  To keep using the v1 in upcoming releases:

- Fix the new deprecations from this release.
- Link with `caqti-dynload` to keep using dynamic loading, or link with the
  needed `caqti-driver-*.v1` driver libraries.
- Link with `caqti.v1` instead of `caqti`.
- Link with `caqti-lwt.v1` instead of `caqti-lwt`.
- Link with `caqti-async.v1` instead of `caqti-async`.

## [0.7.0] - 2017-11-03

- Remove WRAPPER and REPORT functionality.
- Remove deprecated findlib aliases.
- Renamed `date` and `utc` conversions to `date_cl` and `utc_cl`.
- Deprecate `Caqti_metadata` in favour of the new `Caqti_driver_info`.
- Move various signature to separate files, leaving deprecated aliases.

## [0.6.1] - 2017-10-26

- Fixed support for lwt >= 3, but keep supporting 2.7 as well for now.
- Fixed preparation of query after reconnect to PostgreSQL.
- Fixed support for ocaml 4.03.x.
- Added `Tuple.length`.
- Deprecated `Param.sub_types`.
- Deprecated `Param.other` and `Tuple.other`.

## [0.6.0] - 2017-06-05

- Split into separate packages to avoid depopts and rename findlib names
  accordingly.
- Use findlib to load DB drivers, and use `-linkall`. This hopefully solves
  loading issues.

## [0.5.3] - 2017-05-22

- Fix handling of spaces in Sqlite3 URIs and allow setting mode.
- Split `Caqti` (now deprecated) into `Caqti_errors` and `Caqti_connect`.
- Update to async 0.9.0.

## [0.5.2] - 2017-02-25

- Fix plugin loader to handle modernised `META`.

## [0.5.1] - 2017-02-25 retracted

- Rename libraries to match `META`.

## [0.5.0] - 2017-02-25 retracted

- Added MariaDB backend.
- Fixed VARCHAR for SQLite3 describe.


[0.10.1]: https://github.com/paurkedal/ocaml-caqti/compare/v0.10.0...v0.10.1
[0.10.0]: https://github.com/paurkedal/ocaml-caqti/compare/v0.9.0...v0.10.0
[0.9.0]: https://github.com/paurkedal/ocaml-caqti/compare/v0.8.1...v0.9.0
[0.8.1]: https://github.com/paurkedal/ocaml-caqti/compare/v0.8.0...v0.8.1
[0.8.0]: https://github.com/paurkedal/ocaml-caqti/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/paurkedal/ocaml-caqti/compare/v0.6.1...v0.7.0
[0.6.1]: https://github.com/paurkedal/ocaml-caqti/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/paurkedal/ocaml-caqti/compare/v0.5.3...v0.6.0
[0.5.3]: https://github.com/paurkedal/ocaml-caqti/compare/v0.5.2...v0.5.3
[0.5.2]: https://github.com/paurkedal/ocaml-caqti/compare/v0.5.1...v0.5.2
[0.5.1]: https://github.com/paurkedal/ocaml-caqti/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/paurkedal/ocaml-caqti/compare/v0.4.0...v0.5.0
