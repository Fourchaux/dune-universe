(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let html_escape s =
  let buffer = Buffer.create (String.length s * 2) in
  s |> String.iter begin function
    | '&' -> Buffer.add_string buffer "&amp;"
    | '<' -> Buffer.add_string buffer "&lt;"
    | '>' -> Buffer.add_string buffer "&gt;"
    | '"' -> Buffer.add_string buffer "&quot;"
    | '\'' -> Buffer.add_string buffer "&#x27;"
    | c -> Buffer.add_char buffer c
    end;
  Buffer.contents buffer



let to_base64url string =
  Base64.encode_string ~pad:false ~alphabet:Base64.uri_safe_alphabet string

let from_base64url string =
  match Base64.decode ~pad:false ~alphabet:Base64.uri_safe_alphabet string with
  | Error _ -> None
  | Ok result -> Some result



let from_cookie s =
  let pairs =
    s
    |> String.split_on_char ';'
    |> List.map (String.split_on_char '=')
  in

  pairs |> List.fold_left (fun pairs -> function
    | [name; value] -> (String.trim name, String.trim value)::pairs
    | _ -> pairs) []
(* Note: found ocaml-cookie and http-cookie libraries, but they appear to have
   equivalent code for parsing Cookie: headers, so there is no point in using
   them yet, especially as they have stringent OCaml version constraints for
   other parts of their code. *)
(* Note: this parser doesn't actually appear to comply with the RFC strictly. It
   accepts more characters than the spec allows. It doesn't treate DQUOTE
   specially. This might not be important, however, if user agents treat cookies
   as opaque, because then only Dream has to deal with its own cookies. *)

(* TODO Reasonable, secure defaults. *)
let to_set_cookie
    ?expires ?max_age ?domain ?path ?secure ?http_only ?same_site name value =

  let expires =
    match expires with
    | None -> ""
    | Some time ->
      let time = Unix.gmtime time in
      let weekday =
        match time.tm_wday with
        | 0 -> "Sun" | 1 -> "Mon" | 2 -> "Tue" | 3 -> "Wed" | 4 -> "Thu"
        | 5 -> "Fri" | 6 -> "Sat"
        | _ -> assert false
      in
      let month =
        match time.tm_mon with
        | 0 -> "Jan" | 1 -> "Feb" | 2 -> "Mar" | 3 -> "Apr" | 4 -> "May"
        | 5 -> "Jun" | 6 -> "Jul" | 7 -> "Aug" | 8 -> "Sep" | 9 -> "Oct"
        | 10 -> "Nov" | 11 -> "Dec"
        | _ -> assert false
      in
      (* Unix.gmtime docs give range 0..60 for tm_sec, accounting for leap
         seconds. However, RFC 6265 §5.1.1 states:

         5.  Abort these steps and fail to parse the cookie-date if:

           *  the second-value is greater than 59.

           (Note that leap seconds cannot be represented in this syntax.)

         See https://tools.ietf.org/html/rfc6265#section-5.1.1.

         Even though Unix time does not account for leap seconds, in case I
         misunderstand the gmtime API, system differences, or future
         refactoring, make sure no leap seconds creep into the output. *)
      let seconds =
        if time.tm_sec < 60 then
          time.tm_sec
        else
          59
      in
      Printf.sprintf "; Expires=%s, %02i %s %i %02i:%02i:%02i GMT"
        weekday time.tm_mday month (time.tm_year + 1900)
        time.tm_hour time.tm_min seconds
  in

  let max_age =
    match max_age with
    | None -> ""
    | Some seconds -> Printf.sprintf "; Max-Age=%.0f" (floor seconds)
  in

  let domain =
    match domain with
    | None -> ""
    | Some domain -> Printf.sprintf "; Domain=%s" domain
  in

  let path =
    match path with
    | None -> ""
    | Some path -> Printf.sprintf "; Path=%s" path
  in

  let secure =
    match secure with
    | Some true -> "; Secure"
    | _ -> ""
  in

  let http_only =
    match http_only with
    | Some true -> "; HttpOnly"
    | _ -> ""
  in

  let same_site =
    match same_site with
    | None -> ""
    | Some `Strict -> "; SameSite=Strict"
    | Some `Lax -> "; SameSite=Lax"
    | Some `None -> "; SameSite=None"
  in

  Printf.sprintf "%s=%s%s%s%s%s%s%s%s"
    name value expires max_age domain path secure http_only same_site



let iri_safe_octets =
  String.init 128 (fun i -> Char.chr (i + 128))

(* TODO This triggers an upstream bug that causes a mutation. *)
let iri_generic =
  `Custom (`Generic, iri_safe_octets, "")

let to_percent_encoded ?(international = true) string =
  let component =
    if international then iri_generic
    else `Path
    (* TODO Workaround for https://github.com/mirage/ocaml-uri/pull/156; `Path
       should be `Generic. *)
  in
  Uri.pct_encode ~component string

let from_percent_encoded string =
  Uri.pct_decode string



let to_form_urlencoded dictionary =
  dictionary
  |> List.map (fun (name, value) -> name, [value])
  |> Uri.encoded_of_query

let from_form_urlencoded string =
  if string = "" then
    []
  else
    string
    |> Uri.query_of_encoded
    |> List.map (fun (name, values) -> name, String.concat "," values)



let from_target string =
  let uri = Uri.of_string string in
  let query =
    match Uri.verbatim_query uri with
    | Some query -> query
    | None -> ""
  in
  Uri.path uri, query

let from_target_path =
  (* Not tail-recursive. *)
  let rec filter_components = function
    | [] -> []
    | [""] as components -> components
    | ""::components -> filter_components components
    | component::components -> component::(filter_components components)
  in

  fun string ->
    let components =
      if string = "" then
        []
      else
        String.split_on_char '/' string
        |> filter_components
        |> List.map Uri.pct_decode
    in

    components

(* Not tail-recursive. Only called on the site prefix and route fragments during
   app setup. *)
let rec drop_trailing_slash = function
  | [] -> []
  | [""] -> []
  | component::components ->
    component::(drop_trailing_slash components)

(* TODO Currently used mainly for debugging; needs to be replaced by an escaping
   function. *)
let make_path path =
  "/" ^ (String.concat "/" path)



let text_html =
  "text/html; charset=utf-8"

let application_json =
  "application/json"
