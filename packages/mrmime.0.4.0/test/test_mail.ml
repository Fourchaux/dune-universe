let () = Printexc.record_backtrace true

let stream_of_string s =
  let once = ref false in
  fun () ->
    if !once then None
    else (
      once := true;
      Some (s, 0, String.length s))

let stream_of_random ?(chunk = 128) len =
  let ic = open_in "/dev/urandom" in
  let ln = ref 0 in
  let closed = ref false in
  let rs = Bytes.create chunk in
  let go () =
    let len = min (len - !ln) chunk in
    if len == 0 then (
      if not !closed then close_in ic;
      closed := true;
      None)
    else (
      really_input ic rs 0 len;
      ln := !ln + len;
      Some (Bytes.unsafe_to_string rs, 0, len))
  in
  go

let stream_to_string s =
  let b = Buffer.create 4096 in
  let rec go () =
    match s () with
    | Some (buf, off, len) ->
        Buffer.add_substring b buf off len;
        go ()
    | None -> Buffer.contents b
  in
  go ()

let example0 =
  let open Mrmime in
  let john =
    let open Mailbox in
    Local.[ w "john" ] @ Domain.(domain, [ a "gmail"; a "com" ])
  in
  let thomas =
    let open Mailbox in
    Local.[ w "thomas" ] @ Domain.(domain, [ a "gazagnaire"; a "com" ])
  in
  let anil =
    let open Mailbox in
    Local.[ w "anil" ] @ Domain.(domain, [ a "recoil"; a "org" ])
  in

  let header0 =
    let content0 =
      let open Content_type in
      make `Application
        (Subtype.v `Application "pdf")
        Parameters.(of_list [ (k "filename", v "prg.exe") ])
    in
    Header.of_list
      Field.
        [
          Field (Field_name.content_type, Content, content0);
          Field (Field_name.content_encoding, Encoding, `Base64);
        ]
  in

  let header1 =
    let content1 =
      let open Content_type in
      make `Text
        (Subtype.v `Text "plain")
        Parameters.(of_list [ (k "charset", v "utf-8") ])
    in
    Header.of_list
      Field.
        [
          Field (Field_name.content_type, Content, content1);
          Field (Field_name.content_encoding, Encoding, `Quoted_printable);
        ]
  in

  let subject =
    let open Unstructured.Craft in
    compile [ v "First"; sp 1; v "email" ]
  in

  let now = Date.of_ptime ~zone:Date.Zone.GMT (Ptime_clock.now ()) in
  let part0 = Mt.part ~header:header0 (stream_of_random 4096) in
  let part1 = Mt.part ~header:header1 (stream_of_string "Hello World!") in
  let multipart = Mt.multipart ~rng:Mt.rng [ part0; part1 ] in

  let header =
    [
      Field.(Field (Field_name.sender, Mailbox, john));
      Field.(
        Field
          ( Field_name.v "To",
            Addresses,
            Address.[ mailbox thomas; mailbox anil ] ));
      Field.(Field (Field_name.subject, Unstructured, subject));
      Field.(Field (Field_name.date, Date, now));
    ]
  in

  Mt.make (Header.of_list header) Mt.multi multipart

let example1 =
  let open Mrmime in
  let john =
    let open Mailbox in
    Local.[ w "john" ] @ Domain.(domain, [ a "gmail"; a "com" ])
  in
  let thomas =
    let open Mailbox in
    Local.[ w "thomas" ] @ Domain.(domain, [ a "gazagnaire"; a "org" ])
  in
  let anil =
    let open Mailbox in
    Local.[ w "anil" ] @ Domain.(domain, [ a "recoil"; a "org" ])
  in
  let hannes =
    let open Mailbox in
    Local.[ w "hannes" ] @ Domain.(domain, [ a "mehnert"; a "org" ])
  in
  let gemma =
    let open Mailbox in
    Local.[ w "gemma"; w "t"; w "gordon" ]
    @ Domain.(domain, [ a "gmail"; a "com" ])
  in

  let header0 =
    let content0 =
      let open Content_type in
      make `Text
        (Subtype.v `Text "plain")
        Parameters.(of_list [ (k "charset", v "utf-8") ])
    in
    Header.of_list Field.[ Field (Field_name.content_type, Content, content0) ]
  in

  let subject =
    let open Unstructured.Craft in
    compile [ v "Second"; sp 1; v "email" ]
  in

  let now = Date.of_ptime ~zone:Date.Zone.GMT (Ptime_clock.now ()) in
  let part = Mt.part ~header:header0 (stream_of_string "Hello World!") in

  let header =
    [
      Field.(Field (Field_name.sender, Mailbox, john));
      Field.(
        Field
          ( Field_name.v "To",
            Addresses,
            Address.
              [ mailbox thomas; mailbox anil; mailbox hannes; mailbox gemma ] ));
      Field.(Field (Field_name.subject, Unstructured, subject));
      Field.(Field (Field_name.date, Date, now));
    ]
  in

  Mt.make (Header.of_list header) Mt.simple part

let test0 () =
  Alcotest.test_case "example 0" `Quick @@ fun () ->
  let res0 = stream_to_string (Mrmime.Mt.to_stream example0) in
  match
    Angstrom.parse_string ~consume:Angstrom.Consume.All Mrmime.Mail.mail res0
  with
  | Ok _ -> Fmt.epr "%s%!" res0
  | Error _ -> Fmt.invalid_arg "Generate unparsable email"

let test1 () =
  Alcotest.test_case "example 1" `Quick @@ fun () ->
  let res0 = stream_to_string (Mrmime.Mt.to_stream example1) in
  match
    Angstrom.parse_string ~consume:Angstrom.Consume.All Mrmime.Mail.mail res0
  with
  | Ok mail ->
      Fmt.epr "%s%!" res0;
      let gemma_exists (header, _) =
        let open Mrmime in
        let gemma =
          let open Mailbox in
          Local.[ w "gemma"; w "t"; w "gordon" ]
          @ Domain.(domain, [ a "gmail"; a "com" ])
        in
        match Header.assoc (Field_name.v "To") header with
        | Field.Field (_, Field.Addresses, v) :: _ ->
            if List.exists Address.(equal (mailbox gemma)) v then ()
            else Fmt.invalid_arg "Gemma does not exist"
        | _ -> Fmt.invalid_arg "Field \"To\" does not exist"
      in
      gemma_exists mail
  | Error _ -> Fmt.invalid_arg "Generate unparsable email"

let subject =
  "Something larger than 80 columns to see where prettym split contents.A \
   large Subject should be split!"

let example2 =
  let open Mrmime in
  let _, subject = Unstrctrd.safely_decode subject in
  let header =
    [
      Field.(
        Field
          (Field_name.subject, Unstructured, (subject :> Unstructured.elt list)));
    ]
  in
  let part = Mt.part (stream_of_string "Hello World!") in
  Mt.make (Header.of_list header) Mt.simple part

let to_unstrctrd acc = function #Unstrctrd.elt as elt -> elt :: acc | _ -> acc

let to_unstrctrd unstrctrd =
  match
    List.fold_left to_unstrctrd [] unstrctrd |> List.rev |> Unstrctrd.of_list
  with
  | Ok v -> v
  | Error (`Msg err) -> failwith err

let remove_fws (unstrctrd : Unstrctrd.t) =
  let fold acc = function `FWS _ -> acc | x -> x :: acc in
  match
    List.fold_left fold [] (unstrctrd :> Unstrctrd.elt list)
    |> List.rev
    |> Unstrctrd.of_list
  with
  | Ok v -> v
  | Error (`Msg err) -> failwith err

let test2 () =
  Alcotest.test_case "large subject" `Quick @@ fun () ->
  let res0 = stream_to_string (Mrmime.Mt.to_stream example2) in
  match
    Angstrom.parse_string ~consume:Angstrom.Consume.All Mrmime.Mail.mail res0
  with
  | Ok (header, _) -> (
      let open Mrmime in
      match Header.assoc Field_name.subject header with
      | Field.Field (_, Field.Unstructured, v) :: _ ->
          let unstrctrd = to_unstrctrd v in
          let unstrctrd = remove_fws unstrctrd in
          let unstrctrd = Unstrctrd.to_utf_8_string unstrctrd in
          let unstrctrd = String.trim unstrctrd in
          Alcotest.(check string) "Same subject" unstrctrd subject
      | _ -> Fmt.invalid_arg "Field \"Subject\" does not exist")
  | Error _ -> Fmt.invalid_arg "Generate unparsable email"

let () = Alcotest.run "mail" [ ("example", [ test0 (); test1 (); test2 () ]) ]
