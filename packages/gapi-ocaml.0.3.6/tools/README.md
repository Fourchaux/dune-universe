Google APIs Service Generator
=============================

**Warning**: this program is still experimental, it has not yet been tested to
generate correctly all the API bindings. At the moment, the services generated
by this tool are: calendar v3, plus v1, tasks v1, discovery v1, urlshortener
v1, oauth v2, customsearch v1, analytics v3, pagespeedonline v1, blogger v2,
siteVerification v1, adsense v1.1, bigquery v2

The `serviceGenerator` is used to produce OCaml source files that are used to
add a service client to the `gapi` library. This tool will generate 4 OCaml
files:

* `gapi<service name>Model.ml`: contains the data definition of the service
* `gapi<service name>Model.mli`: data definition module interface
* `gapi<service name>Service.ml`: contains the service interface that can be
  used to interact with the Google API
* `gapi<service name>Service.mli`: service module interface

These files should be linked with the `gapi` library that provides the basic
functionalities to query the Google RESTful services.

### Compiling

To build the generator you will need
[ppx_monadic](https://bitbucket.org/camlspotter/ppx_monadic).
After installing it, execute

    $ jbuilder build @generator

### Example

This command will generate the source code of the client for the URL shortener
service (version 1)

    $ _build/default/tools/serviceGenerator.exe -api urlshortener -version v1

