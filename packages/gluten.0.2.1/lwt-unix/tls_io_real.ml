(*----------------------------------------------------------------------------
 *  Copyright (c) 2019 António Nuno Monteiro
 *
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are met:
 *
 *  1. Redistributions of source code must retain the above copyright notice,
 *  this list of conditions and the following disclaimer.
 *
 *  2. Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *
 *  3. Neither the name of the copyright holder nor the names of its
 *  contributors may be used to endorse or promote products derived from this
 *  software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 *  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 *  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 *  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 *  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 *  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 *  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *  POSSIBILITY OF SUCH DAMAGE.
 *---------------------------------------------------------------------------*)

open Lwt.Infix

type descriptor = Tls_lwt.Unix.t

module Io :
  Gluten_lwt.IO with type socket = descriptor and type addr = Unix.sockaddr =
struct
  type socket = descriptor

  type addr = Unix.sockaddr

  let close = Tls_lwt.Unix.close

  let read tls bigstring ~off ~len =
    Lwt.catch
      (fun () ->
        Tls_lwt.Unix.read_bytes tls bigstring off len >|= function
        | 0 ->
          `Eof
        | n ->
          `Ok n)
      (function
        | Unix.Unix_error (Unix.EBADF, _, _) ->
          Lwt.return `Eof
        | exn ->
          Lwt.async (fun () -> close tls);
          Lwt.fail exn)

  let writev tls iovecs =
    Lwt.catch
      (fun () ->
        let cstruct_iovecs =
          List.map
            (fun { Faraday.len; buffer; off } ->
              Cstruct.of_bigarray ~off ~len buffer)
            iovecs
        in
        Tls_lwt.Unix.writev tls cstruct_iovecs >|= fun () ->
        `Ok (Cstruct.lenv cstruct_iovecs))
      (function
        | Unix.Unix_error (Unix.EBADF, "check_descriptor", _) ->
          Lwt.return `Closed
        | exn ->
          Lwt.fail exn)

  let shutdown_send _tls = ()

  let shutdown_receive _tls = ()
end

let null_auth ~host:_ _ = Ok None

let make_client ?alpn_protocols socket =
  let config = Tls.Config.client ?alpn_protocols ~authenticator:null_auth () in
  Tls_lwt.Unix.client_of_fd config socket

let make_server ?alpn_protocols ~certfile ~keyfile socket =
  X509_lwt.private_of_pems ~cert:certfile ~priv_key:keyfile
  >>= fun certificate ->
  let config =
    Tls.Config.server ?alpn_protocols ~certificates:(`Single certificate) ()
  in
  Tls_lwt.Unix.server_of_fd config socket
