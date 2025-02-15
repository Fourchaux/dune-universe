(** Core type definitions *)

open Sexplib.Conv

open Packet
open Ciphersuite

type tls13 = [ `TLS_1_3 ] [@@deriving sexp_of]

type tls_before_13 = [
  | `TLS_1_0
  | `TLS_1_1
  | `TLS_1_2
] [@@deriving sexp_of]

type tls_version = [ tls13 | tls_before_13 ] [@@deriving sexp_of]

let pair_of_tls_version = function
  | `TLS_1_0   -> (3, 1)
  | `TLS_1_1   -> (3, 2)
  | `TLS_1_2   -> (3, 3)
  | `TLS_1_3   -> (3, 4)

let compare_tls_version a b = match a, b with
  | `TLS_1_0, `TLS_1_0 -> 0 | `TLS_1_0, _ -> -1 | _, `TLS_1_0 -> 1
  | `TLS_1_1, `TLS_1_1 -> 0 | `TLS_1_1, _ -> -1 | _, `TLS_1_1 -> 1
  | `TLS_1_2, `TLS_1_2 -> 0 | `TLS_1_2, _ -> -1 | _, `TLS_1_2 -> 1
  | `TLS_1_3, `TLS_1_3 -> 0

let next = function
  | `TLS_1_0 -> Some `TLS_1_1
  | `TLS_1_1 -> Some `TLS_1_2
  | `TLS_1_2 -> Some `TLS_1_3
  | `TLS_1_3 -> None

let all_versions (min, max) =
  let rec gen curr =
    if compare_tls_version max curr >= 0 then
      match next curr with
      | None -> [curr]
      | Some c -> curr :: gen c
    else
      []
  in
  List.rev (gen min)

let tls_version_of_pair = function
  | (3, 1) -> Some `TLS_1_0
  | (3, 2) -> Some `TLS_1_1
  | (3, 3) -> Some `TLS_1_2
  | (3, 4) -> Some `TLS_1_3
  | _      -> None

type tls_any_version = [
  | tls_version
  | `SSL_3
  | `TLS_1_X of int
] [@@deriving sexp_of]

let any_version_to_version = function
  | #tls_version as v -> Some v
  | _ -> None

let version_eq a b =
  match a with
  | #tls_version as x -> compare_tls_version x b = 0
  | _ -> false

let version_ge a b =
  match a with
  | #tls_version as x -> compare_tls_version x b >= 0
  | `SSL_3 -> false
  | `TLS_1_X _ -> true

let tls_any_version_of_pair x =
  match tls_version_of_pair x with
  | Some v -> Some v
  | None ->
     match x with
     | (3, 0) -> Some `SSL_3
     | (3, x) -> Some (`TLS_1_X x)
     | _      -> None

let pair_of_tls_any_version = function
  | #tls_version as x -> pair_of_tls_version x
  | `SSL_3 -> (3, 0)
  | `TLS_1_X m -> (3, m)

let max_protocol_version (_, hi) = hi
let min_protocol_version (lo, _) = lo

type tls_hdr = {
  content_type : content_type;
  version      : tls_any_version;
} [@@deriving sexp_of]

module SessionID = struct
  type t = Cstruct_sexp.t [@@deriving sexp_of]
  let compare = Cstruct.compare
  let hash t = Hashtbl.hash (Cstruct.to_bigarray t)
  let equal = Cstruct.equal
end

module PreSharedKeyID = struct
  type t = Cstruct_sexp.t [@@deriving sexp_of]
  let compare = Cstruct.compare
  let hash t = Hashtbl.hash (Cstruct.to_bigarray t)
  let equal = Cstruct.equal
end

type psk_identity = (Cstruct_sexp.t * int32) * Cstruct_sexp.t [@@deriving sexp_of]

let binders_len psks =
  let binder_len (_, binder) =
    Cstruct.length binder + 1 (* binder len *)
  in
  2 (* binder len *) + List.fold_left (+) 0 (List.map binder_len psks)

type group = [
  | `FFDHE2048
  | `FFDHE3072
  | `FFDHE4096
  | `FFDHE6144
  | `FFDHE8192
  | `X25519
  | `P256
  | `P384
  | `P521
] [@@deriving sexp_of]

let named_group_to_group = function
  | FFDHE2048 -> Some `FFDHE2048
  | FFDHE3072 -> Some `FFDHE3072
  | FFDHE4096 -> Some `FFDHE4096
  | FFDHE6144 -> Some `FFDHE6144
  | FFDHE8192 -> Some `FFDHE8192
  | X25519 -> Some `X25519
  | SECP256R1 -> Some `P256
  | SECP384R1 -> Some `P384
  | SECP521R1 -> Some `P521
  | _ -> None

let group_to_named_group = function
  | `FFDHE2048 -> FFDHE2048
  | `FFDHE3072 -> FFDHE3072
  | `FFDHE4096 -> FFDHE4096
  | `FFDHE6144 -> FFDHE6144
  | `FFDHE8192 -> FFDHE8192
  | `X25519 -> X25519
  | `P256 -> SECP256R1
  | `P384 -> SECP384R1
  | `P521 -> SECP521R1

let group_to_impl = function
  | `FFDHE2048 -> `Finite_field Mirage_crypto_pk.Dh.Group.ffdhe2048
  | `FFDHE3072 -> `Finite_field Mirage_crypto_pk.Dh.Group.ffdhe3072
  | `FFDHE4096 -> `Finite_field Mirage_crypto_pk.Dh.Group.ffdhe4096
  | `FFDHE6144 -> `Finite_field Mirage_crypto_pk.Dh.Group.ffdhe6144
  | `FFDHE8192 -> `Finite_field Mirage_crypto_pk.Dh.Group.ffdhe8192
  | `X25519 -> `X25519
  | `P256 -> `P256
  | `P384 -> `P384
  | `P521 -> `P521

type signature_algorithm = [
  | `RSA_PKCS1_MD5
  | `RSA_PKCS1_SHA1
  | `RSA_PKCS1_SHA224
  | `RSA_PKCS1_SHA256
  | `RSA_PKCS1_SHA384
  | `RSA_PKCS1_SHA512
  | `ECDSA_SECP256R1_SHA1
  | `ECDSA_SECP256R1_SHA256
  | `ECDSA_SECP384R1_SHA384
  | `ECDSA_SECP521R1_SHA512
  | `RSA_PSS_RSAENC_SHA256
  | `RSA_PSS_RSAENC_SHA384
  | `RSA_PSS_RSAENC_SHA512
  | `ED25519
(*  | `ED448
  | `RSA_PSS_PSS_SHA256
  | `RSA_PSS_PSS_SHA384
    | `RSA_PSS_PSS_SHA512 *)
] [@@deriving sexp_of]

let hash_of_signature_algorithm = function
  | `RSA_PKCS1_MD5 -> `MD5
  | `RSA_PKCS1_SHA1 -> `SHA1
  | `RSA_PKCS1_SHA224 -> `SHA224
  | `RSA_PKCS1_SHA256 -> `SHA256
  | `RSA_PKCS1_SHA384 -> `SHA384
  | `RSA_PKCS1_SHA512 -> `SHA512
  | `RSA_PSS_RSAENC_SHA256 -> `SHA256
  | `RSA_PSS_RSAENC_SHA384 -> `SHA384
  | `RSA_PSS_RSAENC_SHA512 -> `SHA512
  | `ECDSA_SECP256R1_SHA1 -> `SHA1
  | `ECDSA_SECP256R1_SHA256 -> `SHA256
  | `ECDSA_SECP384R1_SHA384 -> `SHA384
  | `ECDSA_SECP521R1_SHA512 -> `SHA512
  | `ED25519 -> `SHA512

let signature_scheme_of_signature_algorithm = function
  | `RSA_PKCS1_MD5 -> `RSA_PKCS1
  | `RSA_PKCS1_SHA1 -> `RSA_PKCS1
  | `RSA_PKCS1_SHA224 -> `RSA_PKCS1
  | `RSA_PKCS1_SHA256 -> `RSA_PKCS1
  | `RSA_PKCS1_SHA384 -> `RSA_PKCS1
  | `RSA_PKCS1_SHA512 -> `RSA_PKCS1
  | `RSA_PSS_RSAENC_SHA256 -> `RSA_PSS
  | `RSA_PSS_RSAENC_SHA384 -> `RSA_PSS
  | `RSA_PSS_RSAENC_SHA512 -> `RSA_PSS
  | `ECDSA_SECP256R1_SHA1 -> `ECDSA
  | `ECDSA_SECP256R1_SHA256 -> `ECDSA
  | `ECDSA_SECP384R1_SHA384 -> `ECDSA
  | `ECDSA_SECP521R1_SHA512 -> `ECDSA
  | `ED25519 -> `ED25519

let rsa_sigalg = function
  | `RSA_PSS_RSAENC_SHA256 | `RSA_PSS_RSAENC_SHA384 | `RSA_PSS_RSAENC_SHA512
  | `RSA_PKCS1_SHA256 | `RSA_PKCS1_SHA384 | `RSA_PKCS1_SHA512
  | `RSA_PKCS1_SHA224 | `RSA_PKCS1_SHA1 | `RSA_PKCS1_MD5 -> true
  | `ECDSA_SECP256R1_SHA1 | `ECDSA_SECP256R1_SHA256 | `ECDSA_SECP384R1_SHA384
  | `ECDSA_SECP521R1_SHA512 | `ED25519 -> false

let tls13_sigalg = function
  | `RSA_PSS_RSAENC_SHA256 | `RSA_PSS_RSAENC_SHA384 | `RSA_PSS_RSAENC_SHA512
  | `ECDSA_SECP256R1_SHA256 | `ECDSA_SECP384R1_SHA384
  | `ECDSA_SECP521R1_SHA512 | `ED25519 -> true
  | `RSA_PKCS1_SHA256 | `RSA_PKCS1_SHA384 | `RSA_PKCS1_SHA512
  | `RSA_PKCS1_SHA224 | `RSA_PKCS1_SHA1 | `RSA_PKCS1_MD5
  | `ECDSA_SECP256R1_SHA1 -> false

let pk_matches_sa pk sa =
  match pk, sa with
  | `RSA _, _ -> rsa_sigalg sa
  | `ED25519 _, `ED25519
  | `P256 _, (`ECDSA_SECP256R1_SHA1 | `ECDSA_SECP256R1_SHA256)
  | `P384 _, `ECDSA_SECP384R1_SHA384
  | `P521 _, `ECDSA_SECP521R1_SHA512 -> true
  | _ -> false

module Peer_name = struct
  type t = [ `host ] Domain_name.t
  let sexp_of_t t = Sexplib.Sexp.Atom (Domain_name.to_string t)
end

type client_extension = [
  | `Hostname of Peer_name.t
  | `MaxFragmentLength of max_fragment_length
  | `SupportedGroups of Packet.named_group list
  | `SecureRenegotiation of Cstruct_sexp.t
  | `Padding of int
  | `SignatureAlgorithms of signature_algorithm list
  | `ExtendedMasterSecret
  | `ALPN of string list
  | `KeyShare of (Packet.named_group * Cstruct_sexp.t) list
  | `EarlyDataIndication
  | `PreSharedKeys of psk_identity list
  | `SupportedVersions of tls_any_version list
  | `PostHandshakeAuthentication
  | `Cookie of Cstruct_sexp.t
  | `PskKeyExchangeModes of psk_key_exchange_mode list
  | `ECPointFormats
  | `UnknownExtension of (int * Cstruct_sexp.t)
] [@@deriving sexp_of]

type server13_extension = [
  | `KeyShare of (group * Cstruct_sexp.t)
  | `PreSharedKey of int
  | `SelectedVersion of tls_version (* only used internally in writer!! *)
] [@@deriving sexp_of]

type server_extension = [
  server13_extension
  | `Hostname
  | `MaxFragmentLength of max_fragment_length
  | `SecureRenegotiation of Cstruct_sexp.t
  | `ExtendedMasterSecret
  | `ALPN of string
  | `ECPointFormats
  | `UnknownExtension of (int * Cstruct_sexp.t)
] [@@deriving sexp_of]

type encrypted_extension = [
  | `Hostname
  | `MaxFragmentLength of max_fragment_length
  | `SupportedGroups of group list
  | `ALPN of string
  | `EarlyDataIndication
  | `UnknownExtension of (int * Cstruct_sexp.t)
] [@@deriving sexp_of]

type hello_retry_extension = [
  | `SelectedGroup of group (* only used internally in writer!! *)
  | `Cookie of Cstruct_sexp.t
  | `SelectedVersion of tls_version (* only used internally in writer!! *)
  | `UnknownExtension of (int * Cstruct_sexp.t)
] [@@deriving sexp_of]

type client_hello = {
  client_version : tls_any_version;
  client_random  : Cstruct_sexp.t;
  sessionid      : SessionID.t option;
  ciphersuites   : any_ciphersuite list;
  extensions     : client_extension list
} [@@deriving sexp_of]

type server_hello = {
  server_version : tls_version;
  server_random  : Cstruct_sexp.t;
  sessionid      : SessionID.t option;
  ciphersuite    : ciphersuite;
  extensions     : server_extension list
} [@@deriving sexp_of]

type dh_parameters = {
  dh_p  : Cstruct_sexp.t;
  dh_g  : Cstruct_sexp.t;
  dh_Ys : Cstruct_sexp.t;
} [@@deriving sexp_of]

type hello_retry = {
  retry_version : tls_version ;
  ciphersuite : ciphersuite13 ;
  sessionid : SessionID.t option ;
  selected_group : group ;
  extensions : hello_retry_extension list
} [@@deriving sexp_of]

type session_ticket_extension = [
  | `EarlyDataIndication of int32
  | `UnknownExtension of int * Cstruct_sexp.t
] [@@deriving sexp_of]

type session_ticket = {
  lifetime : int32 ;
  age_add : int32 ;
  nonce : Cstruct_sexp.t ;
  ticket : Cstruct_sexp.t ;
  extensions : session_ticket_extension list
} [@@deriving sexp_of]

type certificate_request_extension = [
  (*  | `StatusRequest *)
  | `SignatureAlgorithms of signature_algorithm list
  (* | `SignedCertificateTimestamp *)
  | `CertificateAuthorities of X509.Distinguished_name.t list
  (* | `OidFilters *)
  (* | `SignatureAlgorithmsCert *)
  | `UnknownExtension of (int * Cstruct_sexp.t)
]

type tls_handshake =
  | HelloRequest
  | HelloRetryRequest of hello_retry
  | EncryptedExtensions of encrypted_extension list
  | ServerHelloDone
  | ClientHello of client_hello
  | ServerHello of server_hello
  | Certificate of Cstruct_sexp.t
  | ServerKeyExchange of Cstruct_sexp.t
  | CertificateRequest of Cstruct_sexp.t
  | ClientKeyExchange of Cstruct_sexp.t
  | CertificateVerify of Cstruct_sexp.t
  | Finished of Cstruct_sexp.t
  | SessionTicket of session_ticket
  | KeyUpdate of key_update_request_type
  | EndOfEarlyData
  [@@deriving sexp_of]

type tls_alert = alert_level * alert_type [@@deriving sexp_of]

(** the master secret of a TLS connection *)
type master_secret = Cstruct_sexp.t [@@deriving sexp_of]

module Cert = struct
  include X509.Certificate
  let sexp_of_t _ = Sexplib.Sexp.Atom "certificate"
end

module Priv = struct
  include X509.Private_key
  let sexp_of_t _ = Sexplib.Sexp.Atom "private key"
end

module Ptime = struct
  include Ptime
  let sexp_of_t ts = Sexplib.Sexp.Atom (Ptime.to_rfc3339 ts)
end

type psk13 = {
  identifier : Cstruct_sexp.t ;
  obfuscation : int32 ;
  secret : Cstruct_sexp.t ;
  lifetime : int32 ;
  early_data : int32 ;
  issued_at : Ptime.t ;
  (* origin : [ `Resumption | `External ] (* using different labels for binder_key *) *)
} [@@deriving sexp_of]

type epoch_state = [ `ZeroRTT | `Established ] [@@deriving sexp_of]

(** information about an open session *)
type epoch_data = {
  state                  : epoch_state ;
  protocol_version       : tls_version ;
  ciphersuite            : Ciphersuite.ciphersuite ;
  peer_random            : Cstruct_sexp.t ;
  peer_certificate_chain : Cert.t list ;
  peer_certificate       : Cert.t option ;
  peer_name              : Peer_name.t option ;
  trust_anchor           : Cert.t option ;
  received_certificates  : Cert.t list ;
  own_random             : Cstruct_sexp.t ;
  own_certificate        : Cert.t list ;
  own_private_key        : Priv.t option ;
  own_name               : Peer_name.t option ;
  master_secret          : master_secret ;
  session_id             : SessionID.t ;
  extended_ms            : bool ;
  alpn_protocol          : string option ;
} [@@deriving sexp_of]

let supports_key_usage ?(not_present = false) usage cert =
  match X509.Extension.(find Key_usage (X509.Certificate.extensions cert)) with
  | None -> not_present
  | Some (_, kus) -> List.mem usage kus

let supports_extended_key_usage ?(not_present = false) usage cert =
  match X509.Extension.(find Ext_key_usage (X509.Certificate.extensions cert)) with
  | None -> not_present
  | Some (_, kus) -> List.mem usage kus
