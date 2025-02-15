(***********************************************************************)
(*                                                                     *)
(*                             Active-DVI                              *)
(*                                                                     *)
(*                   Projet Cristal, INRIA Rocquencourt                *)
(*                                                                     *)
(*  Copyright 2002 Institut National de Recherche en Informatique et   *)
(*  en Automatique.  All rights reserved.  This file is distributed    *)
(*  under the terms of the GNU Lesser General Public License.          *)
(*                                                                     *)
(*  Jun Furuse, Didier R�my and Pierre Weis.                           *)
(*  Contributions by Roberto Di Cosmo, Didier Le Botlan,               *)
(*  Xavier Leroy, and Alan Schmitt.                                    *)
(*                                                                     *)
(*  Based on Mldvi by Alexandre Miquel.                                *)
(***********************************************************************)

(* $Id$ *)


let debugs = Misc.debug_endline;;
(* You may need to make it false for old versions of gs *)
let delaysafer = ref true;; (* false *)
let gslibincwd = Options.flag false "-gs-P" 
  "Passes -P or -P- to look (or not) in the . first when loading libraries";; 


let get_do_ps, set_do_ps, init_do_ps =
 let has_to_do_ps = ref !Global_options.pson in
 (fun () -> !has_to_do_ps),
 (fun b -> has_to_do_ps := b),
 (fun () -> has_to_do_ps := !Global_options.pson);;

let antialias =
  Options.flag false
    "-A"
    "  ask Active-DVI to use PostScript antialiasing,\
    \n\t (the default is not to use PostScript antialiasing).";;

let pstricks =
  Options.flag false
    "-pstricks"
    "  ask Active-DVI to show moveto,\
    \n\t (the default is not to show moveto).";;

let showps_ref = ref false;;
let showps s =
  if !showps_ref then (print_endline  (Printf.sprintf "%s" s));;

(* (Printf.sprintf "SHOWPS: %s" s));;*)

Options.add
  "--showps" (Arg.Set showps_ref)
  "  ask advi to print to stdout a copy\
  \n\t of the PostScript program sent to gs.";;

let pspage = ref 0;;

(* constants *)
(** ack_string is an arbitrary string that would not be ``naturally''
   generated by gs. Xdvi used characters \347\310\376 in octet which is
   \231\200\254 in decimal.
   I don't know why... to test whether gs is new or old *)
let ack_string = "\231\200\254\n";;
let pos_string = "dvi";;
let err_string = "Error:";;
let current_x = ref 0;;
let current_y = ref 0;;

let parse_pos s =
  let c = String.index s ',' in
  (* y comes first, then x *)
  let y = String.sub s 3 (c - 3) in
  let x = String.sub s (c + 1) (String.length s - c - 1) in
  Misc.round (float_of_string x), Misc.round (float_of_string y);;

let ack_request =
  String.concat ""
    [ "flushpage ("; ack_string; ") print flush "; ];;

let timeout = 3.;;

exception Timeout;;
exception Error;;

exception Terminated;;
exception Retry;;

let x11alpha_device = [| "-dNOPLATFONTS"; "-sDEVICE=x11alpha" |];;
let x11_device = [| "-sDEVICE=x11" |];;
type graphical =
    { display : int;
      window  : int32 (* GraphicsY11.window_id *) ; (* Window identifier. *)
      pixmap  : int32 (* GraphicsY11.window_id *) ; (* Pixmap identifier. *)
      width  : int ; (* geometry of the window. *)
      height : int ;
      bwidth  : int ; (* geometry of the backing store. *)
      bheight : int ;
      xdpi : float ; (* x resolution *)
      ydpi : float ; (* y resolution *)
      x    : int   ; (* x offset in pixels
                          (coordinates of the upper left corner) *)
      y    : int   ; (* y offset *)
    };;

exception Killed of string;;

let rec select fd_in fd_out fd_exn timeout =
  (* dirty hack: Graphics uses itimer internally! *)
  let start = Unix.gettimeofday () in
  try
    Unix.select fd_in fd_out fd_exn timeout
  with
  | Unix.Unix_error (Unix.EINTR, _, _) ->
    let now = Unix.gettimeofday () in
    let remaining = start +. timeout -. now in
    if remaining > 0.0 then select fd_in fd_out fd_exn timeout else [], [], []
;;

class gs () =
  let _ = GraphicsY11.window_id() in
  let gr = {
    display = 0;
    window = GraphicsY11.window_id ();
    pixmap = GraphicsY11.bstore_id ();
    width = Graphics.size_x ();
    height = Graphics.size_y ();
    bwidth = GraphicsY11.bsize_x ();
    bheight = GraphicsY11.bsize_y ();
    xdpi = 72.0;
    ydpi = 72.0;
    x = 0;
    y = 0;
  } in
  let dpi = 72 (* unite utilise par dvi? *) in
  let command = !Config.gs_path in
  let command_args =
    Array.concat [
    [|
      command; 
      "-dNOPLATFONTS"; "-dNOPAUSE"; (if !gslibincwd then "-P" else "-P-");
    |];
    (if !antialias then x11alpha_device else x11_device);
    [|
      "-q";
      if !delaysafer then "-dDELAYSAFER" else "-dSAFER";
      "-";
    |]] in

  let _ = debugs command;
    Array.iter debugs command_args in

  (* Set environment so that ghostscript writes in our window. *)
  let _ =
    Unix.putenv "GHOSTVIEW"
      (if Global_options.get_global_display_mode ()
      then Printf.sprintf "%lu " gr.window
      else Printf.sprintf "%lu %lu " gr.window gr.pixmap) in

  let iof = Misc.round and foi = float_of_int in
  let lx = iof ( (foi (gr.x * dpi)) /. gr.xdpi)
  and ly = iof ( (foi (gr.y * dpi)) /. gr.ydpi)
  and ux = iof ( (foi ((gr.x + gr.bwidth)  * dpi)) /. gr.xdpi )
  and uy = iof ( (foi ((gr.y + gr.bheight) * dpi)) /. gr.ydpi) in

  (* Set ghostscript property. *)
  let content =
    Printf.sprintf "%s %d %d %d %d %d %f %f %d %d %d %d"
      "0" (* no backing pixmap for the window *)
      0   (* Rotation : 0 90 180 270 *)
      lx ly ux uy
      (* lower-left x y, upper-right x y :
         Bounding box in default user coordinates. *)
      gr.xdpi gr.ydpi (* Resolution x y. *)
      0 0 0 0 (* Margins left, bottom, top, right. *) in

  let _ =
    begin
      try GraphicsY11.set_named_atom_property  "GHOSTVIEW" content;
      with x -> Misc.fatal_error "Cannot set ``GHOSTVIEW'' property"
    end;
    (* Ignore signal SIGPIPE. *)
    Unix.sigprocmask Unix.SIG_BLOCK [ Sys.sigpipe ] in

  let lpd_in, lpd_out = Unix.pipe () in
  let rpd_in, rpd_out = Unix.pipe () in
  let leftout = Unix.out_channel_of_descr lpd_out in
  let rightin = Unix.in_channel_of_descr rpd_in in
  let close_all () =
    let tryc f x = try f x with _ -> () in
    tryc close_out leftout;
    tryc close_in rightin;
    tryc Unix.close lpd_in;
    tryc Unix.close rpd_in in
  let pid =
    Unix.create_process command command_args lpd_in rpd_out
      (* Unix.stdout *) Unix.stderr
  in
(*
   let () = 
   try 
   match Unix.waitpid  [ Unix.WNOHANG ] pid with
   | _, Unix.WEXITED _ -> failwith (command ^ ":EXITED")
   | _, Unix.WSIGNALED s -> 
   failwith (command ^ ":KILLED:" ^ (string_of_int s))
   | _, Unix.WSTOPPED s -> 
   failwith (command ^ ":STOPPED:" ^ (string_of_int s)) Sys.sigint
   with Unix.Unix_error (Unix.ECHILD, _, _) -> 
   () 
   in
 *)
  object (self)
    val pid = pid
    val mutable ack = 0
    method gr = gr

    method ack_request =
      try
        ack <- ack + 1;
        debugs "calling ack_request";
        self # line ack_request;
        flush leftout;
        debugs "calling ack";
        self # ack;
      with
      | Killed s ->
          self # kill;
          Misc.warning s;
          raise Terminated
      | exn ->
          Misc.warning (Printexc.to_string exn);
          self # kill; 
          raise Terminated

    method ack =
      if ack > 0 then
        begin
          debugs "waiting for input";
          let s =
            
            try input_line rightin
            with End_of_file ->
              match select [ rpd_in ] [] [] 1.0 with
              | [], _, _ ->
                  begin match Unix.waitpid [ Unix.WNOHANG ] pid with
                  | x, Unix.WEXITED y when x > 0 ->
                      raise (Killed "gs exited")
                  | 0, _ ->
                      raise (Killed "gs alive but not responding")
                  | _, _ ->
                      raise (Killed "gs in strange state")
                  end
              | _, _, _ ->
                  input_line rightin in
          debugs s;
          if Misc.has_prefix s ack_string then
            begin
              ack <- ack - 1;
              debugs "gotit";
            end
          else
            if Misc.has_prefix pos_string s then
              begin
                try
                  let x, y = parse_pos s in
                  current_x := x; current_y := y
                with
                | Not_found | Failure _ -> Misc.warning s
              end else
              if Misc.has_prefix err_string s then
                begin
                  Misc.warning s;
                  raise (Killed "Error in Postscript");
                end else
                Misc.warning s;
          self # ack
        end;

    method kill =
      try
        Unix.kill pid Sys.sighup;  (* Sys.sigkill? *)
        let _, _ = Unix.waitpid [] pid in
        close_all ();
      with Unix.Unix_error (_, _, _) -> ()

    method input f =
      let fd = open_in f in
      try 
        showps ("%% PSfile: " ^ f);
        while true do
          output_string leftout (input_line fd);
          output_char leftout '\n';
        done
      with
      | End_of_file ->
          close_in fd
      | exc ->
          close_in fd;
          Misc.warning (Printexc.to_string exc);
          self # kill;
          Misc.warning "GS Terminated"

    method line l =
      try
        showps l;
        output_string leftout l;
        output_char leftout '\n';
      with exc ->
        Misc.warning (Printexc.to_string exc);
        self # kill;
        Misc.warning "GS Terminated"

    method sync =
      try self # ack_request;
      with
        Killed s ->
          self # kill;
          set_do_ps false;
          Misc.warning (Printf.sprintf "%s\nContinuing without gs\n" s)

    method ps b =
      List.iter self#line b;

  end;;

let advi_pro =
"/advi@floatstring 20 string def
/advi@printfloat { advi@floatstring cvs print } def
/advi@CP {
matrix currentmatrix [1 0 0 -1 0 0] setmatrix currentpoint 
(dvi) print advi@printfloat  (,) print advi@printfloat (\n) print
setmatrix } def
";;
let advi_noshowpage = " /showpage { } /def"
let advi_resetmatrix = "[1 0 0 -1 0 0] concat"

type special = Unprotected | Protected | Begin | Continue | End 

let texbegin = "TeXDict begin";;
let texend = "flushpage end";;
let moveto x y =
  (*   current_x := x; current_y := y; *)
  Printf.sprintf "%d %d moveto" x y
;;

(* This is sent to the process, so as to fix a bug in gs 8.60... *)
let dummy_string = 
"
/dummydummy {
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
} def
";;

let make_header (b, h) =
  if b then
    String.concat "\n"
      [ "TeXDict begin @defspecial";
        h;
        "@fedspecial end"; ]
  else String.concat "" [ "("; h; ") run" ];;

let texc_special_pro gv =
  let l = [ "texc.pro"; "special.pro" ] in
  try
    let l' = Search.true_file_names [] l in
    if List.length l = List.length l' then
      List.map (fun s -> make_header (false, s)) l'
        (* Fixes A bug in ack_string, but I don't know how... *)
     else raise Not_found
  with
    Not_found ->
      Misc.warning "Cannot find Postscript prologues: texc.pro or special.pro";
      Misc.warning "Continuing without Postscript specials";
      gv # kill;
      set_do_ps false;
      [];;

let parent_dir_regexp = Str.regexp (Str.quote Filename.parent_dir_name)
let parent_dir_in_path f = Str.string_match parent_dir_regexp f 0


class gv =
  object (self)
    val mutable dirtypage = true
    val mutable process : gs option = None
    val mutable dpi = 72
    val mutable mag = 1.
    val mutable xorig = 0
    val mutable yorig = 0
    val mutable sync = true
    val mutable headers = []
    method line =
      try
        self # process # line
      with Terminated ->
        process <- None;
        raise Terminated
    method moveto x y =
      let x' = x + xorig in
      let y' = y - yorig  in
      moveto x' y'

    method current_point =
      let x' = !current_x in
      let y' = !current_y + (self # process # gr).height in
      x', y'

    method check_size =
      begin
        match process with
        | None -> ()
        | Some gs ->
            let gr = gs # gr in
            let size_x = GraphicsY11.bsize_x () in
            let size_y = GraphicsY11.bsize_y () in
            if size_x <> gr.bwidth || size_y <> gr.bheight
            then self # kill;
      end;

    method sync =
      if not sync then
        begin
          match process with
          | Some p -> p # sync; sync <- true
          | None -> ()
        end

    method add_headers l =
      if headers = [] then headers <- texc_special_pro self;
      let l = List.map make_header l in
      match
        List.filter 
          (function s -> List.for_all (function s' -> s <> s') headers)
          l
      with
      | [] -> ()
      | l ->
          headers <- headers @ l;
          match process with
          | Some gs ->
              gs # line "grestore SI restore";
              List.iter (gs # line) l; 
              (* to avoid no-current-point *)
              gs # line "0 0 moveto";
              gs # line "/SI save def gsave";
          | None -> ()

    method newpage l sdpi m x y =
      self # check_size;
      let l = List.map make_header l in
      let l = List.filter (fun s -> not (List.mem s headers)) l in
      if l <> [] then headers <- headers @ l;
      let gs = self # process in
      dpi <- sdpi;
      mag <- m;
      xorig <- x;
      yorig <- (gs # gr).height - y;
      if !pspage > 0 then showps "showpage";
      if !pspage > 0 then gs # line "erasepage";
      incr pspage;
      showps (Printf.sprintf "%%%%Page: %d %d\n" !pspage !pspage);
      gs # line "\n%% Newpage\n";
      gs # line "grestore";
      gs # line "0 0 moveto";
      if l <> [] then gs # line "SI restore";
      gs # line
        (Printf.sprintf
           "TeXDict begin %d %d div dup /Resolution X /VResolution X end"
           dpi dpi);
      gs # line
        (Printf.sprintf
           "TeXDict begin /DVImag %f def end"
           mag);
      List.iter gs # line l;
      if l <> [] then gs # line  "/SI save def";
      gs # line "gsave";
      gs # sync


    method process =
      match process with
      | None ->
          if not (get_do_ps ()) then raise Terminated;
          let gs = new gs () in
          if headers = [] then headers <-  texc_special_pro self;
          (* should take matrix as a parameter ? *)
          showps "%!PS-Adobe-2.0\n%%Creator: Active-DVI\n%!";
          gs # line "[1 0 0 -1 0 0] concat";
          gs # line dummy_string;
          List.iter (gs # line) headers;
          gs # line advi_pro;
          gs # line "TeXDict begin @landscape end";
          gs # line "/SI save def gsave";
          if !delaysafer then gs # line ".setsafe";
          process <- Some gs;
          gs
      | Some gs ->
(*prerr_endline (Printf.sprintf "Calling existing gs interpreter");*)
          gs

    method send b  =
(*prerr_endline (Printf.sprintf "Calling gv#SEND with\n\t\t %s" (String.concat " " b));*)
      self # check_size;
      self # process # ps b;
      sync <- false

    method def (b : string) =
      (* insert into postscript into user dictionnary, typically with '!'
         should not change graphic parameters *)
      (* does not draw---no flushpage *)
      (* in fact b should have already be loaded through *)
      self # send [ ]


    method ps action b (x : int) (y : int) =
      (* prerr_endline (Printf.sprintf "Calling gv#PS with\n\t\t %s" b); *)
      self # send
        begin match action with
        | Unprotected ->
            (* insert non protected postscript, typically with ``ps:''
               may (not ?) change graphic parameters;
               still need to set current point for initclip PStrick specials.
             *)
            [ texbegin; self # moveto x y; b; texend ];
        | Protected ->
            (* insert protected postscript, typically with '"'
               does (?) change graphic parameters *)
            [ texbegin;
              self # moveto x y;
              "@beginspecial @setspecial";
              b;
              "@endspecial"; texend;
            ] ;
        | Begin ->
            (* Open SDict as @beginspecial
               but do not reset graphical parameters *)
            [ texbegin; 
              self # moveto x y;
              "@defspecial"; 
              b ];
        | Continue -> 
            (* Continue [in SDict] *)
            [ b ];
        | End -> 
            (* Close SDict *)
            [ "@fedspecial"; texend; ];
        end; 
      sync <- false

    method file name (llx, lly, urx, ury) (rwi, rhi : int * int) x y =
      (* insert into postscript into user dictionnary, typically with '!'
         should not change graphic parameters *)
      (* does not draw---no flushpage *)
      try
        let truename = Search.true_file_name [] name in 
        try
          Unix.access truename [ Unix.R_OK ];
          (*
             if Filename.is_relative truename then
             if parent_dir_in_path truename then
             Misc.warning
             (Printf.sprintf "Cannot load PS file (%s in path): %s"
             Filename.parent_dir_name 
             truename) 
             else *)
          let ri z s = if z <> 0 then Printf.sprintf "%d %s" z s else "" in
          self # send [ texbegin;
                        self # moveto x y;
                        "@beginspecial";
                        Printf.sprintf "%d @llx %d @lly %d @urx %d @ury"
                          llx lly urx ury;
                        ri rwi "@rwi"; ri rhi "@rhi";
                        "@setspecial";
                      ];
          (* self # send [ Printf.sprintf"(%s) run" truename; ]; *)
          self # process # input  truename;
          self # send [ "@endspecial";
                        texend;
                      ];
          sync <- false
              (*
                 else
                 Misc.warning
                 (Printf.sprintf "Cannot load PS file (absolute path): %s"
                 truename)  *)
        with
        | Unix.Unix_error ((Unix.EACCES | Unix.ENOENT as err), _, _) -> 
            Misc.warning
              (Printf.sprintf "Cannot load PS file (%s): %s"
                 (if err = Unix.ENOENT then "nonexistent" else "access")
                 truename)
      with 
      | Not_found -> ()


    method kill =
      showps "showpage";
      match process with
      | None -> ()
      | Some gs ->
          gs # kill;
          process <- None
  end
;;

let gv = new gv;;

(* exported functions *)

let kill () = gv # kill;;

let ps_forms =
  [ 
    "ps: ", Unprotected;
    "\" ", Protected;
    "ps::[begin]", Begin;
    "ps::[end]", End;
    "ps::", Continue;
    "ps:", Unprotected;
   ];;

let setrgbcolor r g b = 
  if get_do_ps () then
(*     let _ =     Printf.eprintf "%d %d %d setrgbcolor\n%!" r g b in *)
    let ratio x = float (x * 100 / 255) *. 0.01 in
    gv#ps Continue (Printf.sprintf "%.2f %.2f %.2f setrgbcolor" 
                      (ratio r) (ratio g) (ratio b)) 0 0;;

let draw s x y =
  if get_do_ps () then
    let pred (prefix, action) =
      try gv#ps action (Misc.get_suffix prefix s) x y; true
      with Misc.Match -> false in
    if not (List.exists pred ps_forms) then
      try gv#ps Protected (Misc.get_suffix  "\" " s) x y with Misc.Match ->
        try gv#def (Misc.get_suffix  "! " s) with Misc.Match -> 
(*
   | Misc.Match ->
   try gv#file (Misc.get_suffix  "psfile: " s) bbox size x y with
 *)
          Misc.warning
            (Printf.sprintf "Unknown PostScript commands\n\t\t %s" s)
;;
let draw_file fname bbox ri x y =
  if get_do_ps () then gv#file fname bbox ri x y;;

let current_point() =
    gv#current_point;;

let add_headers x =
  gv#add_headers x;;

let newpage x =
  gv#newpage x;;

let flush () =
  if get_do_ps () then
    try  gv # sync
    with
    | Terminated ->
        Misc.warning "Continuing without Postscript";
        gv#kill;
        set_do_ps false;;

let toggle_antialiasing () =
  antialias := not !antialias;
  kill ();;

