open Lwt.Infix

module Calc = Examples.Calc

let pp_qid f = function
  | None -> ()
  | Some x ->
    let s = Uint32.to_string x in
    Fmt.(styled `Magenta (fun f x -> Fmt.pf f " (qid=%s)" x)) f s

let reporter =
  let report src level ~over k msgf =
    let src = Logs.Src.name src in
    msgf @@ fun ?header ?(tags=Logs.Tag.empty) fmt ->
    let qid = Logs.Tag.find Capnp_rpc.Debug.qid_tag tags in
    let print _ =
      Fmt.(pf stdout) "%a@." pp_qid qid;
      over ();
      k ()
    in
    Fmt.kpf print Fmt.stdout ("%a %a: @[" ^^ fmt ^^ "@]")
      Fmt.(styled `Magenta string) (Printf.sprintf "%11s" src)
      Logs_fmt.pp_header (level, header)
  in
  { Logs.report = report }

let serve addr : unit =
  Lwt_main.run @@ Capnp_rpc_unix.serve ~offer:Examples.Calc.service addr

let connect addr =
  Lwt_main.run begin
    Lwt_switch.with_switch @@ fun switch ->
    let calc = Capnp_rpc_unix.connect ~switch addr in
    Logs.info (fun f -> f "Evaluating expression...");
    let remote_add = Calc.Client.getOperator calc `Add in
    let result = Calc.Client.evaluate calc Calc.(Call (remote_add, [Float 40.0; Float 2.0])) in
    Calc.Client.read result >>= fun v ->
    Fmt.pr "Result: %f@." v;
    Lwt.return_unit
  end

open Cmdliner

let connect_addr =
  let i = Arg.info [] ~docv:"ADDR" ~doc:"Address of server, e.g. unix:/run/my.socket" in
  Arg.(required @@ pos 0 (some Capnp_rpc_unix.Connect_address.conv) None i)

let listen_addr =
  let i = Arg.info [] ~docv:"ADDR" ~doc:"Address to listen on, e.g. unix:/run/my.socket" in
  Arg.(required @@ pos 0 (some Capnp_rpc_unix.Listen_address.conv) None i)

let serve_cmd =
  Term.(const serve $ listen_addr),
  let doc = "provide a Cap'n Proto calculator service" in
  Term.info "serve" ~doc

let connect_cmd =
  Term.(const connect $ connect_addr),
  let doc = "connect to a Cap'n Proto calculator service" in
  Term.info "connect" ~doc

let default_cmd =
  let doc = "a calculator example" in
  Term.(ret (const (`Help (`Pager, None)))),
  Term.info "calc" ~version:"v0.1" ~doc

let cmds = [serve_cmd; connect_cmd]

let () =
  Fmt_tty.setup_std_outputs ();
  Logs.set_reporter reporter;
  Logs.set_level ~all:true (Some Logs.Info);
  Term.eval_choice default_cmd cmds |> Term.exit
