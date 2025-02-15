## [1.0.1] - 2021-09-17
### Added
- Support `multipart/form-data` in CSRF middleware

## [1.0.0] - 2021-09-08
### Fixed
- It is now possible to register multiple instances of the same service type simultaneously
- Rename page title of queue dashboard
- Document `EMAIL_BYPASS_INTERCEPT` and `QUEUE_FORCE_ASYNC`
- Accept `true`, `True` and `1` for truthy boolean env vars
- Document global middlewares
- Fix issue where the default smtp certs path is an empty string
- Fix trailing slash middleware to work with `PREFIX_PATH`

### Changed
- The `search_query` for `Sihl.Database.prepare_search_request` has to return the total amount of rows for that query without limit. On PostgreSQL and MariaDB this can be done with `COUNT(*) OVER() as total`. No `count_query`is needed anymore.

#### User service
- Add optional `given_name` and `name`
- Deprecate `update_details` in favor of `update`
- Consistent use of named arguments in service API

### Added
- Optional argument `format_filter` for formatting the search keyword when filtering in `Sihl.Database.prepare_search_request`

## [0.6.0] - 2021-04-30
### Added
- Add CLI generators as built-in CLI commands `gen.service` (for generating CRUD services), `gen.view` (for generating CRUD views) and `gen.html` (for generating CRUD RESTful resources)
- `Sihl.Web.Rest.{query, to_query_string, of_query_string, next_page, previous_page, last_page, first_page, query_filter, query_sort, query_limit, query_offset}`
- Add ParcelJS based asset pipeline to template project in `template`
- Database helpers to conveniently run exactly one caqti request `Sihl.Database.find`, `Sihl.Database.find_opt`, `Sihl.Database.exec` and `Sihl.Database.collect`
- The `search` function of the user service from `sihl-user` takes an optional argument `offset`. This allows you to implement offset based pagination.

### Changed
- Replace the usaged of `Lwt.Syntax` with `lwt_ppx` for nicer error messages in your Sihl apps
- Rework built-in commands (`start` is now `server`, commands are namespaced with `.`)
- The command function in `Sihl.Command.make` returns `unit option Lwt.t` and Sihl takes care of printing the usage if `Lwt.return None` is returned
- Replaced `Sihl.Database.prepare_requests` with `Sihl.Database.prepare_search_request`
- Replaced `Sihl.Database.run_request` with `Sihl.Database.run_search_request`
- Make search query type `'a Sihl.Database.prepared_search_query` abstract to reduce API clutter. The search queries are highly specific to the implementation and are not likely to be re-used independently from `run_search_request`.
- Change `query` to fully fledged `search` in `Sihl.Rest.SERVICE` to support paginated, filtered and sorted views

## [0.5.0] - 2021-04-10
### Added
- `Sihl.Web.Rest` provides helpers to quickly create HTML resources. This is useful to expose any service of type `Sihl.Web.Rest.SERVICE` through the Internet by making it part of a web app.

## [0.4.1] - 2021-03-31
### Fixed
- Register timezone removal migration in `sihl-queue`. This makes it easy to change the timezone on the server without breaking applications.

## [0.4.0] - 2021-03-27
### Changed
- Get rid of `Sihl.Web.Middleware.htmx`, `Sihl.Web.Htmx` can be used directly now
- `Sihl.Web.Csrf.find` returns `string option`, use `Option.get` if you are sure that the CSRF middleware has been applied
- Take custom `unauthenticated_handler` for `Sihl.Web.Middleware.bearer_token` and enforce existence of `Bearer` token in `Authorization` header
- Web helpers moved from `Sihl.Web.Http` to `Sihl.Web`. In `Sihl.Web.Http` there is only the Opium based HTTP service.
- Replace middlewares with helpers where they don't have to be middlewares such as bearer token (`Sihl.Web.Request.bearer_token`), htmx (`Sihl.Web.Htmx`) and session (`Sihl.Web.Session`)
- Remove `form` middleware (`Sihl.Web.Middleware.form`), use `Sihl.Web.Request` directly to parse form requests
- Replace `Sihl.Web.Flash.find_custom` with `Sihl.Web.Flash.find` and `Sihl.Web.Flash.set_custom` with `Sihl.Web.Fash.set` to support key-value based semantics. If you need to store your custom string, simply store it under a key like `Sihl.Web.Flash.set [("custom", value)] resp` and retrieve it with `Sihl.Web.Flash.find "custom" request`
- Use `conformist` 0.4.0

### Added
- Read `Request-ID-X` header if present instead of generating a random id for`Sihl.Web.Id`
- Implement composable router API `Sihl.Web.{get, post, ...}` and `Sihl.Web.choose`.
- Implement job queue dashboard for `sihl-queue`

## [0.3.0] - 2021-03-12
### Fixed
- Replace functor based approach with service facade pattern based approach to increase ergonomy
- Move `user_token` middleware to `sihl-token` package

### Added
- Implement MariaDB and PostgreSql backends for all services except storage service
- JSON Web Token backend for the token service
- Default middlewares for server side rendered forms and JSON API

## [0.2.2] - 2020-12-17
### Fixed
- Merge form data and urlencoded form parsing and provide them in one middleware

## [0.2.1] - 2020-12-09
### Fixed
- Two subsequent `POST` request works now with the CSRF middleware

## [0.2] - 2020-12-07
### Fixed
- Extract `sihl-core`, `sihl-type`, `sihl-contract`, `sihl-user`, `sihl-persistence` and `sihl-web` as separate opam packages
- Increase session key size to 20 bytes
- Sign session cookies with `SIHL_SECRET`
- Simplify session service API
- Implement generic flash storage on top of session storage and replace the specific message service
- Update to httpaf-based Opium 0.19.0

### Added
- File log reporter to store logs in `logs/error.log` and `logs/app.log`
- Add log source to log text

## [0.1.10] - 2020-11-18
### Fixed
- Properly load `.env` files based on project root, can be set using `ENV_FILES_PATH`
- Add custom error types for user actions to allow overriding errors displayed to users

### Added
- Determine project rood using markers such as the .git folder

## [0.1.9] - 2020-11-16
### Fixed
- Get rid of `Core.Ctx.t`
- Make sure migrations and repo cleaners are registered when registering service
- `Sihl.Core.*` modules are now accessible directly under `Sihl.*`

## [0.1.8] - 2020-11-12
### Fixed
- Get rid of `Result.get_ok` because it swallows errors

## [0.1.7] - 2020-11-03
### Fixed
- Simplify `Database.Service` API: Only provide `transaction`, `query` and `fetch_pool`
- Fixe dune package names, private dune packages don't have generic names like `http` or `database` causing conflicts in a Sihl app

## [0.1.6] - 2020-10-31
### Fixed
- `Database.Service` and `Repository.Service` are assumed to have just one implementation, so they are referenced directly in service implementations instead of passing them as functor arguments
- Extract `Random.Service` from utils as standalone top level service
- Merge utils into one `utils.ml` file
#### HTTP API
- `Sihl.Http.Response` and `Sihl.Http.Request` have consistent API
- `Sihl.Middleware` contains all provided middlewares
- Implement multi-part form data parsing

## [0.1.5] - 2020-10-14
### Fixed
- Remove seed service since the same functionality
- Simplify app abstraction, instead of `with_` use service APIs directly
- Extract storage service as `sihl-storage` opam package
- Extract email service as `sihl-email` opam package
- Extract queue service as `sihl-queue` opam package
- Move configuration and logging into core, neither of the are implemented as services
- Replace `pcre` with `re` as regex library to get rid of a system dependency on pcre
- Split up `Sihl.Data` into `Sihl.Migration`, `Sihl.Repository` and `Sihl.Database`
- Move module signatures from `Foo.Service.Sig` to `Foo.Sig`, the services might live in a third party opam package, but the signatures are staying in `sihl`
- Move `Sihl.App` to `Sihl.Core.App` and simplify app API
- Move log service, config service and cmd service into core (they don't have to be provided to other services through functors)
- Simplify Sihl app creation and service configuration

## [0.1.4] - 2020-09-24
### Fixed
- Remove `reason` and `tyxml-jsx` as dependency as they are not used anymore

### Added
- Various combinators for `Sihl.Seed.t` including constructor and field accessors

## [0.1.3] - 2020-09-14
### Added
- Seed Service with commands `seedlist` and `seedrun <name>`

### Fixed
- Lifecycle API: A service now has two additional functions `start` and `stop`, which are used in the lifecycle definition
- Database service query functions `query`, `atomic` and `with_connection` can now be nested

## [0.1.2] - 2020-09-09
### Fixed
- Re-export `Sihl.Queue.Job.t`
- Export content types under `Sihl.Web`

## [0.1.1] - 2020-09-07
### Fixed
- Don't raise exception when user login fails if it is a user error
- Remove dev tools as dev dependencies

### Added
- Storage service can remove files
- Move README.md documentation to ocamldoc based documentation

## [0.1.0] - 2020-09-03
### Fixed
- DB connection leaks caused deadlocks
- Provide all service dependencies using functors
- Move Opium & Cohttp specific stuff into the web server service implementation to allow for swappable implementation based on something like httpaf
- Inject log service to all other services by default

### Added
- Support letters 0.2.0 for SMTP emailing
- Switch to exception based service API
- HTTP Response API to respond with file `Sihl.Web.Res.file`

## [0.0.56] - 2020-08-17
### Fixed
- Stop running integration tests during OPAM release

## [0.0.55] - 2020-08-17
### Added
- Initial release of Sihl
