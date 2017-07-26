(* Copyright (C) 2015, Thomas Leonard
   See the README file for details. *)

open Lwt.Infix
open Formats.GUI
open Utils

module QV = Msg_chan.Make(Framing)

let src = Logs.Src.create "qubes.gui" ~doc:"Qubes GUId agent"
module Log = (val Logs.src_log src : Logs.LOG)

let qubes_gui_protocol_version_linux = 0x10000l

let gui_agent_port =
  match Vchan.Port.of_string "6000" with
  | `Error msg -> failwith msg
  | `Ok port -> port

type t = QV.t

let connect ~domid () =
  Log.info (fun f -> f "waiting for client...");
  QV.server ~domid ~port:gui_agent_port () >>= fun gui ->
  let version = Cstruct.create sizeof_gui_protocol_version in
  set_gui_protocol_version_version version qubes_gui_protocol_version_linux;
  QV.send gui [version] >>= function
  | `Eof -> Lwt.fail (error "End-of-file sending protocol version")
  | `Ok () ->
  QV.recv_fixed gui sizeof_xconf >>= function
  | `Eof -> Lwt.fail (error "End-of-file getting X configuration")
  | `Ok conf ->
  let w = get_xconf_w conf in
  let h = get_xconf_h conf in
  Log.info (fun f -> f "client connected (screen size: %ldx%ld)" w h);
  Lwt.return gui

let rec listen t =
  QV.recv_raw t >>= function
  | `Eof -> failwith "End-of-file from GUId in dom0"
  | `Ok buf ->
      Log.warn (fun f -> f "Unexpected data: %S" (Cstruct.to_string buf));
      listen t
