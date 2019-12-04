open Defaults

let default d o = CCOpt.get_or ~default:d o

(* List all keys of a TOML table
   This is used to retrieve a list of widgets to call
 *)
let list_config_keys table =
  TomlTypes.Table.fold (fun k _ ks -> (TomlTypes.Table.Key.to_string k) :: ks ) table []

(** Checks if config file exists.
    When config doesn't exist, soupault uses default settings,
    so this is considered a normal condition.

    When we cannot even check if it exists or not, however, something is clearly
    so wrong that there's no point in doing anything else.
    *)
let config_exists file =
  try
     FileUtil.test (FileUtil.Exists) file
  with Unix.Unix_error (errno, _, _) ->
    let msg = Unix.error_message errno in
    let () = Logs.warn @@ fun m -> m "Could not check if config file %s exists: %s" file msg in
    exit 1

let common_widget_options = [
  "widget";
  "path_regex"; "exclude_path_regex";
  "page"; "exclude_page";
  "section"; "exclude_section";
  "after"
]

let bad_option_msg opt ident suggestion =
  let suggestion_msg =
    (match suggestion with
    | None -> ""
    | Some s -> Printf.sprintf "Did you mean \"%s\"?" s)
  in Printf.sprintf "Option \"%s\" is not valid for %s. %s" opt ident suggestion_msg

(** Checks for invalid config options *)
let check_options ?(fmt=bad_option_msg) valid_options config ident =
  let check_option valid_options opt =
    if not (List.exists ((=) opt) valid_options) then
    let index = Spellcheck.make_index valid_options in
    let suggestion = Spellcheck.get_suggestion index opt in
    Logs.warn @@ fun m -> m "%s" (fmt opt ident suggestion)
  in
  let keys = list_config_keys config in
  List.iter (check_option valid_options) keys

(** Read and parse a TOML file *)
let read_config path =
  if not (config_exists path) then
    let () = Logs.warn @@ fun m -> m "Configuration file %s not found, using default settings" path in
    Ok None
  else
  try
    let open Toml.Parser in
    let conf = from_filename path |> unsafe in
    Ok (Some conf)
  with
  | Sys_error err -> Error (Printf.sprintf "Could not read config file: %s" err)
  | Toml.Parser.Error (err, _) -> Error (Printf.sprintf "Could not parse config file %s: %s" path err)

let get_table name config = TomlLenses.(get config (key name |-- table))
let get_table_result err name config = get_table name config |> CCOpt.to_result err

let get_string k tbl = TomlLenses.(get tbl (key k |-- string))
let get_string_default default_value k tbl = get_string k tbl |> default default_value
let get_string_result err k tbl = get_string k tbl |> CCOpt.to_result err

let get_bool k tbl = TomlLenses.(get tbl (key k |-- bool))
let get_bool_default default_value k tbl = get_bool k tbl |> default default_value
let get_bool_result err k tbl = get_bool k tbl |> CCOpt.to_result err

let get_int k tbl = TomlLenses.(get tbl (key k |-- int))
let get_int_default default_value k tbl = get_int k tbl |> default default_value
let get_int_result err k tbl = get_int k tbl |> CCOpt.to_result err

let get_strings k tbl = TomlLenses.(get tbl (key k |-- array |-- strings))
let get_strings_default default_value k tbl = get_strings k tbl |> default default_value
let get_strings_result err k tbl = get_strings k tbl |> CCOpt.to_result err

(* For passing options to plugins *)
let get_whatever_as_string k tbl =
  (* A "maybe not" "monad" *)
  let (>>=) v f =
    match v with
    | None -> f v
    | Some _ as v -> v
  in
  get_string k tbl >>=
  (fun _ -> get_int k tbl |> CCOpt.map string_of_int) >>=
  (fun _ -> get_bool k tbl |> CCOpt.map string_of_bool)

(** Converts a TOML table to an assoc list using a given value retrieval function,
    ignoring None's it may return.
  *)
let assoc_of_table f tbl =
  let has_value (_, v) = match v with Some _ -> true | None -> false in
  let keys = list_config_keys tbl in
  List.fold_left (fun xs k -> (k, f k tbl ) :: xs) [] keys |>
  List.filter has_value |>
  List.map (fun (k, v) -> k, Utils.unwrap_option v)

(** Tries to get a string list from a config
    If there's actually a string list, just returns it.
    If there's a single string, considers it a single item list.
    If there's nothing like a string at all, return the default.
 *)
let get_strings_relaxed ?(default=[]) k tbl =
  let strs = get_strings k tbl in
  match strs with
  | Some strs -> strs
  | None -> begin
      let str = get_string k tbl in
      match str with
      | Some str -> [str]
      | None -> default
    end

let string_of_assoc xs =
  let xs = List.map (fun (k, v) -> Printf.sprintf "%s = %s" k v) xs in
  String.concat ", " xs

(* Update global settings with values from the config, if there are any *)
let _get_preprocessors config =
  let pt = get_table Defaults.preprocessors_table config in
  match pt with
  | None -> []
  | Some pt -> assoc_of_table get_string pt

let _get_index_queries index_table =
  let bind = CCResult.(>>=) in
  let get_query k queries =
    let%bind qt = get_table_result "value is not an inline table" k queries in
    let%bind selector = get_string_result "selector option is missing or value is not a string" "selector" qt in
    let select_all = get_bool_default false "select_all" qt in
    Ok {field_name = k; field_selector = selector; select_all = select_all}
  in
  let rec get_queries ks queries acc =
    match ks with
    | [] -> acc
    | k :: ks ->
      begin
        let q = get_query k queries in
        match q with
        | Error e ->
          let () = Logs.warn @@ fun m -> m "Malformed index field query \"%s\": %s" k e in
          get_queries ks queries acc
        | Ok q -> get_queries ks queries (q :: acc)
      end
  in
  let qt = get_table "custom_fields" index_table in
  match qt with
  | None -> []
  | Some qt -> get_queries (list_config_keys qt) qt []

let valid_index_options = [
  "custom_fields"; (* subtable rather than option *)
  "index"; "dump_json"; "newest_entries_first";
  "index_selector"; "index_title_selector"; "index_excerpt_selector";
  "index_date_selector"; "index_author_selector";
  "index_date_format"; "index_item_template"; "index_processor";
  "ignore_template_errors"; "extract_after_widgets"; "strip_tags"
]

let _get_index_settings settings config =
  let get_item_template s c =
    let tmpl_string = get_string_default Defaults.default_index_item_template "index_item_template" c in
    try
      Mustache.of_string tmpl_string
    with _ ->
      let () = Logs.warn @@ fun m -> m "Failed to parse template \"%s\", using default" tmpl_string in
      s.index_item_template
  in
  let st = get_table Defaults.index_settings_table config in
  match st with
  | None -> settings
  | Some st ->
    let () = check_options valid_index_options st "table \"index\"" in
    {settings with
       index = get_bool_default settings.index "index" st;
       dump_json = get_string "dump_json" st;
       newest_entries_first = get_bool_default settings.newest_entries_first "newest_entries_first" st;
       index_selector = get_string_default settings.index_selector "index_selector" st;
       index_title_selector = get_strings_relaxed ~default:settings.index_title_selector "index_title_selector" st;
       index_excerpt_selector = get_strings_relaxed ~default:settings.index_excerpt_selector "index_excerpt_selector" st;
       index_date_selector = get_strings_relaxed ~default:settings.index_date_selector "index_date_selector" st;
       index_author_selector = get_strings_relaxed ~default:settings.index_author_selector "index_author_selector" st;
       index_date_format = get_string_default settings.index_date_format "index_date_format" st;
       index_item_template = get_item_template settings st;
       index_processor = get_string "index_processor" st;
       ignore_template_errors = get_bool_default settings.ignore_template_errors "ignore_template_errors" st;
       index_extract_after_widgets = get_strings_relaxed "extract_after_widgets" st;
       index_custom_fields = _get_index_queries st;
       index_strip_tags = get_bool_default settings.index_strip_tags "strip_tags" st;
    }

let valid_settings = [
  "verbose"; "debug"; "strict"; "site_dir"; "build_dir";
  "content_selector"; "doctype"; "index_page"; "index_file";
  "default_template"; "clean_urls"; "page_file_extensions";
  "ignore_extensions"; "complete_page_selector"; "generator_mode"
]

let _update_settings settings config =
  let st = get_table Defaults.settings_table config in
  match st with
  | None ->
     let () = Logs.warn @@ fun m -> m "Could not find the [settings] section in the config, using defaults" in
     settings
  | Some st ->
    let () = check_options valid_settings st "table \"settings\"" in
    {default_settings with
       verbose = get_bool_default settings.verbose "verbose" st;
       debug = get_bool_default settings.debug "debug" st;
       strict = get_bool_default settings.strict "strict" st;
       site_dir = get_string_default settings.site_dir "site_dir" st;
       build_dir = get_string_default settings.build_dir "build_dir" st;
       content_selector = get_string_default settings.content_selector "content_selector" st;
       doctype = get_string_default settings.doctype "doctype" st;
       index_page = get_string_default settings.index_page "index_page" st;
       index_file = get_string_default settings.index_file "index_file" st;
       default_template = get_string_default settings.default_template "default_template" st;
       clean_urls = get_bool_default settings.clean_urls "clean_urls" st;
       page_extensions = get_strings_relaxed ~default:settings.page_extensions "page_file_extensions" st;
       ignore_extensions = get_strings_relaxed ~default:[] "ignore_extensions" st;
       complete_page_selector = get_string_default settings.complete_page_selector "complete_page_selector" st;
       generator_mode = get_bool_default settings.generator_mode "generator_mode" st;

       preprocessors = _get_preprocessors config
     }

let valid_tables = ["settings"; "index"; "plugins"; "widgets"; "preprocessors"]

let update_settings settings config =
  let bad_section_msg tbl _ suggestion =
    (* Yay, duplicate code! *)
    let suggestion_msg =
      (match suggestion with
      | None -> ""
      | Some s -> Printf.sprintf "Did you mean [%s]?" s)
    in Printf.sprintf "[%s] is not a valid config section. %s" tbl suggestion_msg
  in
  match config with
  | None -> settings
  | Some config ->
    let () = check_options ~fmt:bad_section_msg valid_tables config "table \"settings\"" in
    let settings = _update_settings settings config in
    _get_index_settings settings config
