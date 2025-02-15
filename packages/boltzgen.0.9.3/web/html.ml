(******************************************************************************)
(* Copyright (c) 2016 DooMeeR                                                 *)
(*                                                                            *)
(* Permission is hereby granted, free of charge, to any person obtaining      *)
(* a copy of this software and associated documentation files (the            *)
(* "Software"), to deal in the Software without restriction, including        *)
(* without limitation the rights to use, copy, modify, merge, publish,        *)
(* distribute, sublicense, and/or sell copies of the Software, and to         *)
(* permit persons to whom the Software is furnished to do so, subject to      *)
(* the following conditions:                                                  *)
(*                                                                            *)
(* The above copyright notice and this permission notice shall be             *)
(* included in all copies or substantial portions of the Software.            *)
(*                                                                            *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,            *)
(* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF         *)
(* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND                      *)
(* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE     *)
(* LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION     *)
(* OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION      *)
(* WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.            *)
(******************************************************************************)

(* Modification by Benoit Barbot *)

open Js_of_ocaml

type t = Dom.node Js.t


let append_node parent node =
  let _: Dom.node Js.t = parent##appendChild(node) in
  ()


let set_items parent (items: t list) =
  List.iter
    (fun child -> let _: Dom.node Js.t = parent##removeChild(child) in ())
    (Dom.list_of_nodeList parent##.childNodes);
  List.iter (append_node parent) items

let get_by_id' ?on_change s =
    let e = Js_of_ocaml.Dom_html.getElementById s in
  (match on_change, 
         Js.Opt.to_option @@ Dom_html.CoerceTo.textarea e,
         Js.Opt.to_option @@ Dom_html.CoerceTo.input e with
    Some f,Some e2,_ -> 
     let on_input _ = f (Js.to_string e2##.value); Js._true in
     e2##.oninput := Dom.handler on_input;
   | Some f,_, Some e2 -> 
      let on_input = if e2##._type = Js.string "checkbox" then
                       (fun _ -> f (string_of_bool (Js.to_bool e2##.checked)); Js._true)
                     else
                       (fun _ -> f (Js.to_string e2##.value); Js._true)
      in
      e2##.oninput := Dom.handler on_input;
   | _ -> ());
  (e :> t), set_items e


let get_by_id ?on_change s =
  let e,_ = get_by_id' ?on_change s in
  e

let get_value_by_id s () =
    let e = Js_of_ocaml.Dom_html.getElementById s in
    (match Js.Opt.to_option @@ Dom_html.CoerceTo.textarea e,
           Js.Opt.to_option @@ Dom_html.CoerceTo.input e with
       Some e2,_ -> Js.to_string e2##.value 
   | _, Some e2 -> Js.to_string e2##.value 
   | _ -> "Fail")

let alert x =
  Dom_html.window##alert(Js.string x)

let br () =
  let br = Dom_html.document##createElement(Js.string "BR") in
  (br :> t)

let text value =
  let text = Dom_html.document##createTextNode(Js.string value) in
  (text :> t)

let text' value =
  let text = Dom_html.document##createTextNode(Js.string value) in
  let set_text value = text##replaceData 0 text##.length (Js.string value) in
  (text :> t), set_text

let img ?(class_ = "") ?alt ?title src =
  let alt = match alt with None -> src | Some alt -> alt in
  let img = Dom_html.(createImg document) in
  img##.src := Js.string src;
  img##.alt := Js.string alt;
  img##.className := Js.string class_;
  (match title with None -> () | Some title -> img##.title := Js.string title);
  (img :> t)

let a ?(class_ = "") ?(href = "") ?(title="") ?(on_click = fun () -> ()) items =
  let a = Dom_html.(createA document) in
  let append_node node =
    let _: Dom.node Js.t = a##appendChild(node) in
    ()
  in
  List.iter append_node items;
  a##.title := Js.string title;
  a##.className := Js.string class_;
  a##.href := Js.string href;
  let on_click _ = on_click (); Js._true in
  a##.onclick := Dom.handler on_click;
  (a :> t)

let kbd' value =
  let kbd = Dom_html.document##createElement(Js.string "kbd") in
  let textv,textup = text' value in
  ignore @@ kbd##appendChild(textv);
  ( kbd :> t),textup


let button ?(class_ = "") ?(on_click = fun () -> ()) items =
  let button = Dom_html.(createButton document) in
  let append_node node =
    let _: Dom.node Js.t = button##appendChild(node) in
    ()
  in
  List.iter append_node items;
  button##.className := Js.string class_;
  let on_click _ = on_click (); Js._true in
  button##.onclick := Dom.handler on_click;
  (button :> t)


let hi i value =
  let hi = Dom_html.document##createElement(Js.string ("H"^string_of_int i)) in
  append_node hi (text value);
  ( hi :> t)

let p' ?(class_ = "") items =
  let p = Dom_html.(createP document) in
  List.iter (append_node p) items;
  p##.className := Js.string class_;
  (p :> t), set_items p

let p ?class_ items =
  let p, _ = p' ?class_ items in
  p

let p_text ?class_ string =
  p ?class_ [ text string ]

let div' ?(class_ = "") ?(title="") ?id items =
  let div = Dom_html.(createDiv document) in
  List.iter (append_node div) items;
  (match id with None -> () | Some ids -> div##.id := Js.string ids);
  div##.title := Js.string title;
  div##.className := Js.string class_;
  (div :> t), set_items div

let div ?class_ ?title ?id items =
  let div, _ = div' ?class_ ?title ?id items in
  div

let span' ?(class_ = "") items =
  let span = Dom_html.(createSpan document) in
  List.iter (append_node span) items;
  span##.className := Js.string class_;
  (span :> t), set_items span

let span ?class_ items =
  let span, _ = span' ?class_ items in
  span

let checkbox_input' ?(class_ = "") ?(on_change = fun _ -> ()) checked =
  let input = Dom_html.(createInput ~_type: (Js.string "checkbox") document) in
  input##.checked := Js.bool checked;
  let on_click _ = on_change (Js.to_bool input##.checked); Js._true in
  input##.onclick := Dom.handler on_click;
  input##.className := Js.string class_;
  let set_checked checked = input##.checked := Js.bool checked in
  (input :> t), set_checked

let checkbox_input ?class_ ?on_change checked =
  let checkbox_input, _ = checkbox_input' ?class_ ?on_change checked in
  checkbox_input

let radio_input' ?(class_ = "") ?(on_change = fun _ -> ()) ?(name = "")
    checked =
  let input =
    Dom_html.(
      createInput ~name: (Js.string name) ~_type: (Js.string "radio")
        document
    )
  in
  input##.checked := Js.bool checked;
  let on_click _ = on_change (Js.to_bool input##.checked); Js._true in
  input##.onclick := Dom.handler on_click;
  input##.className := Js.string class_;
  let set_checked checked = input##.checked := Js.bool checked in
  (input :> t), set_checked

let radio_input ?class_ ?on_change ?name checked =
  let radio_input, _ = radio_input' ?class_ ?on_change ?name checked in
  radio_input

let text_input' ?(class_ = "") ?(on_change = fun _ -> ()) ?(_type = "text") value =
  let input = Dom_html.(createInput ~_type: (Js.string _type) document) in
  input##.value := Js.string value;
  let on_input _ = on_change (Js.to_string input##.value); Js._true in
  input##.oninput := Dom.handler on_input;
  input##.className := Js.string class_;
  let set_value value = input##.value := Js.string value in
  (input :> t), set_value

let option value =
  let opt = Dom_html.(createOption document) in
  opt##.value := Js.string value;
  append_node opt (text value);
  (opt :> t)

let select ?(class_ = "") ?(on_change = fun _ -> ()) sl =
  let sel = Dom_html.(createSelect document) in
  List.iter (fun s -> append_node sel (option s)) sl;
  let on_input _ = on_change (Js.to_string sel##.value); Js._true in
  sel##.oninput := Dom.handler on_input;
  sel##.className := Js.string class_;
  (sel :> t)


let text_input ?class_ ?on_change ?_type value =
  let text_input, _ = text_input' ?class_ ?on_change ?_type value in
  text_input

let text_area' ?(class_ = "") ?(on_change = fun _ -> ()) ?(is_read_only =false) value =
  let input = Dom_html.(createTextarea document) in
  input##.value := Js.string value;
  if is_read_only then input##setAttribute (Js.string "readonly") (Js.string "true");
  let on_input _ = on_change (Js.to_string input##.value); Js._true in
  input##.oninput := Dom.handler on_input;
  input##.className := Js.string class_;
  let set_value value = input##.value := Js.string value in
  (input :> t), set_value

let text_area ?class_ ?on_change ?is_read_only value =
  let text_area, _ = text_area' ?class_ ?on_change value in
  text_area

let run html =
  let on_load _ =
    let html = html () in
    let body =
      let find_tag name =
        let elements =
          Dom_html.window##.document##getElementsByTagName(Js.string name)
        in
        let element =
          Js.Opt.get (elements##item(0))
            (fun () -> failwith ("find_tag("^name^")"))
        in
        element
      in
      find_tag "body"
    in
    let _: t = body##appendChild(html) in
    Js._false
  in
  Dom_html.window##.onload := Dom.handler on_load

let get_hash () =
  let fragment = Dom_html.window##.location##.hash |> Js.to_string in
  if fragment = "" then
    ""
  else if fragment.[0] = '#' then
    String.sub fragment 1 (String.length fragment - 1)
  else
    fragment

let set_hash hash =
  Dom_html.window##.location##.hash := Js.string hash

let on_hash_change handler =
  let handler _ = handler (); Js._true in
  Dom_html.window##.onhashchange := Dom.handler handler
