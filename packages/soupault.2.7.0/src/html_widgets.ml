(* HTML tree manipulation widgets *)

open Widget_utils

let (let*) = Stdlib.Result.bind

(** Deletes an element from the tree *)
let delete_element _ config soup =
  let valid_options = List.append Config.common_widget_options ["selector"; "only_if_empty"; "delete_all"] in
  let () = Config.check_options valid_options config "widget \"delete_element\"" in
  let selector = Config.get_string_result "Missing required option \"selector\"" "selector" config in
  let when_empty = Config.get_bool_default false "only_if_empty" config in
  let delete_all = Config.get_bool_default true "delete_all" config in
  match selector with
  | Error _ as e -> e
  | Ok selector ->
    let nodes =
      if delete_all then (Soup.select selector soup |> Soup.to_list)
      else (Soup.select_one selector soup |> (fun n -> match n with Some n -> [n] | None -> []))
    in
    begin
      match nodes with
      | [] ->
         Logs.debug @@ fun m -> m "Page has no elements matching selector \"%s\", nothing to delete" selector
      | ns ->
        let _delete when_empty n =
          if not (Html_utils.is_empty n) && when_empty then
            Logs.debug @@ fun m -> m "Element matching selector \"%s\" is not empty, configured to delete only when empty" selector
          else Soup.delete n
        in List.iter (_delete when_empty) ns
    end;
    Ok ()

(** Wraps elements matching certain selectors into an HTML snippet. *)
let wrap _ config soup =
  let wrap_elem s w e =
    let w_soup = Soup.parse w in
    (* XXX: This is a rather inelegant dirty hack.
       Since the wrapper comes from outside the page element tree,
       it's not enough to insert elements into it, we also need to get it into the original tree.
       Since we can only insert the wrapped element when we know wrapping worked fine,
       we can't get the wrapper into the tree early.
       That's why we first "clone" the "wrappee" by exporting it to string and parsing it again,
       then create a separate tree from the wrapper and the wrappee,
       and finally replace the original element with it.

       If this turns out to have undesirable side effects,
       we'll need to search for better hacks. *)
    let* () = Html_utils.wrap ~selector:s w_soup (Soup.to_string e |> Soup.parse) in
    let () = Soup.replace e w_soup in
    Ok ()
  in
  let valid_options = List.append Config.common_widget_options ["selector"; "wrapper"; "wrap_all"; "wrapper_selector"] in
  let () = Config.check_options valid_options config "widget \"wrap\"" in
  let selectors = get_selectors config in
  let wrapper_selector = Config.get_string_opt "wrapper_selector" config in
  let wrap_all = Config.get_bool_default true "wrap_all" config in
  match selectors with
  | Error _ as e -> e
  | Ok selectors ->
    let containers =
      if wrap_all then Html_utils.select_all selectors soup
      else (match Html_utils.select_any_of selectors soup with None -> [] | Some e -> [e])
    in
    begin
      match containers with
      | [] ->
        let () = no_container_action selectors in Ok ()
      | _ ->
        let* wrapper_str = Config.get_string_result "Missing required option \"wrapper\"" "wrapper" config in
        let* () = Utils.iter (wrap_elem wrapper_selector wrapper_str) containers in
        Ok ()
    end
