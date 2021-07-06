type answer = Yes | No

open Bos_setup.R.Infix

let ask_yes_no f ~default_answer =
  let options : ('a, Format.formatter, unit, unit) format4 =
    match default_answer with Yes -> " [Y/n]" | No -> " [y/N]"
  in
  App_log.question (fun l ->
      f (fun ?header ?tags fmt -> l ?header ?tags (fmt ^^ options)))

let rec loop_yes_no ~question ~default_answer =
  ask_yes_no question ~default_answer;
  match String.lowercase_ascii (read_line ()) with
  | "" when default_answer = Yes -> true
  | "" when default_answer = No -> false
  | "y" | "yes" -> true
  | "n" | "no" -> false
  | _ ->
      App_log.unhappy (fun l ->
          l
            "Please answer with \"y\" for yes, \"n\" for no or just hit enter \
             for the default");
      loop_yes_no ~question ~default_answer

let confirm ~question ~yes ~default_answer =
  if yes then true else loop_yes_no ~question ~default_answer

let confirm_or_abort ~question ~yes ~default_answer =
  if confirm ~question ~yes ~default_answer then Ok ()
  else Error (`Msg "Aborting on user demand")

let rec try_again ?(limit = 1) ~question ~yes ~default_answer f =
  match f () with
  | Ok x -> Ok x
  | Error (`Msg err) when limit > 0 ->
      App_log.unhappy (fun l -> l "%s" err);
      confirm_or_abort ~yes ~question ~default_answer >>= fun () ->
      try_again ~limit:(limit - 1) ~question ~yes ~default_answer f
  | Error x -> Error x

let ask ~question ~default_answer =
  let pp_default fmt default =
    match default with
    | Some default ->
        Fmt.pf fmt "[press ENTER to use '%a']" Fmt.(styled `Bold string) default
    | None -> ()
  in
  App_log.question (fun l -> l "%s%a" question pp_default default_answer)

let rec loop ~question ~default_answer =
  ask ~question ~default_answer;
  let answer =
    match read_line () with
    | "" -> None
    | s -> Some s
    | exception End_of_file -> None
  in
  match (answer, default_answer) with
  | Some s, _ -> s
  | None, Some default -> default
  | None, None ->
      App_log.unhappy (fun l -> l "dune-release needs an answer to proceed.");
      loop ~question ~default_answer

let user_input ?default_answer ~question () = loop ~question ~default_answer
