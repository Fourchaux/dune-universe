open Mirage

(* boilerplate from https://github.com/mirage/ocaml-git.git unikernel/config.ml
   (commit #3bfcf215f959b71580e5c0b655700bb9484aee8c) *)
type mimic = Mimic

let mimic = typ Mimic

let mimic_count =
  let v = ref (-1) in
  fun () -> incr v ; !v

let mimic_conf () =
  let packages = [ package "mimic" ] in
  impl @@ object
       inherit base_configurable
       method ty = mimic @-> mimic @-> mimic
       method module_name = "Mimic.Merge"
       method! packages = Key.pure packages
       method name = Fmt.str "merge_ctx%02d" (mimic_count ())
       method! connect _ _modname =
         function
         | [ a; b ] -> Fmt.str "Lwt.return (Mimic.merge %s %s)" a b
         | [ x ] -> Fmt.str "%s.ctx" x
         | _ -> Fmt.str "Lwt.return Mimic.empty"
     end

let merge ctx0 ctx1 = mimic_conf () $ ctx0 $ ctx1

let mimic_tcp_conf =
  let packages = [ package "git-mirage" ~sublibs:[ "tcp" ] ] in
  impl @@ object
       inherit base_configurable
       method ty = stackv4v6 @-> mimic
       method module_name = "Git_mirage_tcp.Make"
       method! packages = Key.pure packages
       method name = "tcp_ctx"
       method! connect _ modname = function
         | [ stack ] ->
           Fmt.str {ocaml|Lwt.return (%s.with_stack %s %s.ctx)|ocaml}
             modname stack modname
         | _ -> assert false
     end

let mimic_tcp_impl stackv4v6 = mimic_tcp_conf $ stackv4v6

let mimic_ssh_conf ~kind ~seed ~auth =
  let seed = Key.abstract seed in
  let auth = Key.abstract auth in
  let packages = [ package "git-mirage" ~sublibs:[ "ssh" ] ] in
  impl @@ object
       inherit base_configurable
       method ty = stackv4v6 @-> mimic @-> mclock @-> mimic
       method! keys = [ seed; auth; ]
       method module_name = "Git_mirage_ssh.Make"
       method! packages = Key.pure packages
       method name = match kind with
         | `Rsa -> "ssh_rsa_ctx"
         | `Ed25519 -> "ssh_ed25519_ctx"
       method! connect _ modname =
         function
         | [ _; tcp_ctx; _ ] ->
             let with_key =
               match kind with
               | `Rsa -> "with_rsa_key"
               | `Ed25519 -> "with_ed25519_key"
             in
             Fmt.str
               {ocaml|let ssh_ctx00 = Mimic.merge %s %s.ctx in
                      let ssh_ctx01 = Option.fold ~none:ssh_ctx00 ~some:(fun v -> %s.%s v ssh_ctx00) %a in
                      let ssh_ctx02 = Option.fold ~none:ssh_ctx01 ~some:(fun v -> %s.with_authenticator v ssh_ctx01) %a in
                      Lwt.return ssh_ctx02|ocaml}
               tcp_ctx modname
               modname with_key Key.serialize_call seed
               modname Key.serialize_call auth
         | _ -> assert false
     end

let mimic_ssh_impl ~kind ~seed ~auth stackv4v6 mimic_git mclock =
  mimic_ssh_conf ~kind ~seed ~auth
  $ stackv4v6
  $ mimic_git
  $ mclock

(* TODO(dinosaure): user-defined nameserver and port. *)

let mimic_dns_conf =
  let packages = [ package "git-mirage" ~sublibs:[ "dns" ] ] in
  impl @@ object
       inherit base_configurable
       method ty = random @-> mclock @-> time @-> stackv4v6 @-> mimic @-> mimic
       method module_name = "Git_mirage_dns.Make"
       method! packages = Key.pure packages
       method name = "dns_ctx"
       method! connect _ modname =
         function
         | [ _; _; _; stack; tcp_ctx ] ->
             Fmt.str
               {ocaml|let dns_ctx00 = Mimic.merge %s %s.ctx in
                      let dns_ctx01 = %s.with_dns %s dns_ctx00 in
                      Lwt.return dns_ctx01|ocaml}
               tcp_ctx modname
               modname stack
         | _ -> assert false
     end

let mimic_dns_impl random mclock time stackv4v6 mimic_tcp =
  mimic_dns_conf $ random $ mclock $ time $ stackv4v6 $ mimic_tcp

type paf = Paf
let paf = typ Paf

let paf_conf () =
  let packages = [ package "paf" ~sublibs:[ "mirage" ] ] in
  impl @@ object
    inherit base_configurable
    method ty = time @-> stackv4v6 @-> paf
    method module_name = "Paf_mirage.Make"
    method! packages = Key.pure packages
    method name = "paf"
  end

let paf_impl time stackv4v6 = paf_conf () $ time $ stackv4v6

let mimic_paf_conf () =
  let packages = [ package "git-paf" ] in
  impl @@ object
       inherit base_configurable
       method ty = time @-> pclock @-> stackv4v6 @-> paf @-> mimic @-> mimic
       method module_name = "Git_paf.Make"
       method! packages = Key.pure packages
       method name = "paf_ctx"
       method! connect _ modname = function
         | [ _; _; _; _; tcp_ctx; ] ->
             Fmt.str
               {ocaml|let paf_ctx00 = Mimic.merge %s %s.ctx in
                      Lwt.return paf_ctx00|ocaml}
               tcp_ctx modname
         | _ -> assert false
     end

let mimic_paf_impl time pclock stackv4v6 paf mimic_tcp =
  mimic_paf_conf ()
  $ time
  $ pclock
  $ stackv4v6
  $ paf
  $ mimic_tcp
(* --- end of copied code --- *)

let net = generic_stackv4v6 default_network

let seed =
  let doc = Key.Arg.info ~doc:"Seed for the ssh private key." ["seed"] in
  Key.(create "seed" Arg.(opt (some string) None doc))

let authenticator =
  let doc = Key.Arg.info ~doc:"Authenticator for SSH." ["authenticator"] in
  Key.(create "authenticator" Arg.(opt (some string) None doc))

(* set ~tls to false to get a plain-http server *)
let http_srv = cohttp_server @@ conduit_direct ~tls:true net

(* TODO: make it possible to enable and disable schemes without providing a port *)
let http_port =
  let doc = Key.Arg.info ~doc:"Listening HTTP port." ["http"] ~docv:"PORT" in
  Key.(create "http_port" Arg.(opt (some int) None doc))

let https_port =
  let doc = Key.Arg.info ~doc:"Listening HTTPS port." ["https"] ~docv:"PORT" in
  Key.(create "https_port" Arg.(opt (some int) None doc))

let certs = generic_kv_ro ~key:Key.(value @@ kv_ro ()) "tls"
let zap = generic_kv_ro ~key:Key.(value @@ kv_ro ()) "caldavzap"

let admin_password =
  let doc = Key.Arg.info ~doc:"Password for the administrator." ["admin-password"] ~docv:"STRING" in
  Key.(create "admin_password" Arg.(opt (some string) None doc))

let remote =
  let doc = Key.Arg.info ~doc:"Location of calendar data." [ "remote" ] ~docv:"REMOTE" in
  Key.(create "remote" Arg.(required string doc))

let tofu =
  let doc = Key.Arg.info ~doc:"If a user does not exist, create them and give them a new calendar." [ "tofu" ] in
  Key.(create "tofu" Arg.(flag doc))

let hostname =
  let doc = Key.Arg.info ~doc:"Hostname to use." [ "host" ] ~docv:"STRING" in
  Key.(create "hostname" Arg.(required string doc))

let apple_testable =
  let doc = Key.Arg.info ~doc:"Configure the server to use with Apple CCS CalDAVtester." [ "apple-testable" ] in
  Key.(create "apple_testable" Arg.(flag doc))

let main =
  let direct_dependencies = [
    package "uri" ;
    package ~pin:"git+https://github.com/roburio/caldav.git" "caldav" ;
    package ~min:"0.1.3" "icalendar" ;
    package ~min:"2.6.0" "irmin-git" ;
    package ~min:"2.6.0" "irmin-mirage-git" ;
    package ~min:"3.4.0" "git-mirage";
  ] in
  let keys =
    [ Key.abstract seed ; Key.abstract authenticator ;
      Key.abstract http_port ; Key.abstract https_port ;
      Key.abstract admin_password ; Key.abstract remote ;
      Key.abstract tofu ; Key.abstract hostname ;
      Key.abstract apple_testable ]
  in
  foreign
    ~packages:direct_dependencies ~keys
    "Unikernel.Main" (random @-> pclock @-> mimic @-> kv_ro @-> http @-> kv_ro @-> job)

let mimic ~kind ~seed ~authenticator stackv4v6 random mclock pclock time paf =
  let mtcp = mimic_tcp_impl stackv4v6 in
  let mdns = mimic_dns_impl random mclock time stackv4v6 mtcp in
  let mssh = mimic_ssh_impl ~kind ~seed ~auth:authenticator stackv4v6 mtcp mclock in
  let mpaf = mimic_paf_impl time pclock stackv4v6 paf mtcp in
  merge mpaf (merge mssh mdns)

let mimic =
  mimic ~kind:`Rsa ~seed ~authenticator net
    default_random default_monotonic_clock default_posix_clock default_time
    (paf_impl default_time net)

let () =
  register "caldav" [main $ default_random $ default_posix_clock $ mimic $ certs $ http_srv $ zap ]
