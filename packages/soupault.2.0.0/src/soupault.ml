open Defaults

module FU = FileUtil
module FP = FilePath

(* Result monad *)
let (>>=) = Stdlib.Result.bind
let (let*) = (>>=)

let mkdir dir =
  (* Note: FileUtil.mkdir returns success if the directory
     already exists, this is why it's not checked before creation. *)
  try Ok (FU.mkdir ~parent:true dir)
  with FileUtil.MkdirError e -> Error e

(*** Logging setup ***)

(* Omit the executable name from the logs, the user knows already *)
let pp_header ppf (l, h) =
  match h with
  | None -> if l = Logs.App then () else Format.fprintf ppf "[%a] " Logs.pp_level l
  | Some h -> Format.fprintf ppf "[%s] " h

let log_reporter = Logs.format_reporter ~pp_header:pp_header  ()

let setup_logging verbose debug =
  let level =
    if debug then Logs.Debug
    else if verbose then Logs.Info
    else Logs.Warning
  in
  Logs.set_level (Some level);
  Logs.set_reporter log_reporter

(*** Filesystem stuff ***)
let (+/) left right =
    FP.concat left right

let list_dirs path =
    FU.ls path |> FU.filter FU.Is_dir

let remove_ignored_files settings files =
  let ignored settings file = Utils.in_list settings.ignore_extensions (Utils.get_extension file) in
  List.filter (fun f -> not (ignored settings f)) files

let list_section_files settings path =
  let is_page_file f = Utils.in_list settings.page_extensions (Utils.get_extension f) in
  let files = FU.ls path |> FU.filter (FU.Is_file) |> remove_ignored_files settings in
  let page_files = List.find_all is_page_file files in
  let other_files = List.find_all (fun f -> not (is_page_file f)) files in
  page_files, other_files

let make_build_dir build_dir =
  if (FU.test FU.Exists build_dir) then Ok () else
  let () = Logs.info @@ fun m -> m "Build directory \"%s\" does not exist, creating" build_dir in
  mkdir build_dir

(** Produces a target directory name for the page.

    If clean URLs are used, then a subdirectory matching the page name
    should be created inside the section directory, unless the page is
    a section index page.
    E.g. "site/foo.html" becomes "build/foo/index.html" to provide
    a clean URL.

    If clean URLs are not used, only section dirs are created.
 *)
let make_page_dir_name settings target_dir page_name =
  if (page_name = settings.index_page) || (not settings.clean_urls) then target_dir
  else target_dir +/ page_name

let load_html settings file =
  let ext = Utils.get_extension file in
  let preprocessor = List.assoc_opt ext settings.preprocessors in
  try
    match preprocessor with
    | None -> Ok (Soup.read_file file |> Soup.parse)
    | Some prep ->
      let prep_cmd = Printf.sprintf "%s %s" prep file in
      let () = Logs.info @@ fun m -> m "Calling preprocessor %s on page %s" prep file in
      Utils.get_program_output prep_cmd [| |] >>= (fun h -> Ok (Soup.parse h))
  with Sys_error e -> Error e

let save_html settings soup file =
  try
    let html_str = Soup.pretty_print soup in
    (* lambdasoup 0.7.1 adds an HTML5 doctype whether you want it or not.
       Until it stops doing that or adds an option to choose a doctype,
       we have to remove it so that we can add a doctype from the config. *)
    let html_str = Re.replace  ~f:(fun _ -> "") (Re.Perl.compile_pat ~opts:[`Caseless] "^(<!DOCTYPE[^>]*>\\s*)") html_str in
    let chan = open_out file in
    (* lambdasoup doesn't include the doctype even if it was present
       in the source, so we have to do it ourselves *)
    settings.doctype |> String.trim |> Printf.fprintf chan "%s\n";
    Soup.write_channel chan html_str;
    close_out chan;
    Ok ()
  with Sys_error e -> Error e

let include_content selector html content =
  let element = Soup.select_one selector html in
  match element with
  | Some element -> Ok (Soup.append_child element content)
  | None ->
    Error (Printf.sprintf "No element in the template matches selector \"%s\", nowhere to insert the content"
           selector)

let make_page settings page_file content =
  (* If generator mode is off, treat everything like a complete page *)
  if not settings.generator_mode then Ok content else
  let page_wrapper_elem = Soup.select_one settings.complete_page_selector content in
  (* If page file appears to be a complete page rather than a page body,
     just return it *)
  match page_wrapper_elem with
  | Some _ ->
    let () =
      if settings.generator_mode then
      Logs.debug @@ fun m -> m "File appears to be a complete page, not using the page template"
      (* in HTML processor mode that's implied *)
    in Ok content
  | None ->
    let tmpl = List.find_opt
      (fun t -> (Path_options.page_included t.template_path_options settings.site_dir page_file) = true)
      settings.page_templates
    in
    let html, content_selector = (match tmpl with
      | None ->
        let () = Logs.info @@ fun m -> m "Using the default template for page %s" page_file in
        (Soup.parse settings.default_template_source, Some settings.default_content_selector)
      | Some t ->
        let () = Logs.info @@ fun m -> m "Using template \"%s\" for page %s" t.template_name page_file in
        (Soup.parse t.template_data, t.template_content_selector))
    in
    let content_selector = Option.value ~default:settings.default_content_selector content_selector in
    let* () = include_content content_selector html content in
    Ok html

(* Widget processing *)
let rec process_widgets env settings ws wh config soup =
  match ws with
  | [] -> Ok ()
  | w :: ws' ->
    begin
      let open Widgets in
      let widget = Hashtbl.find wh w in
      let () = Logs.info @@ fun m -> m "Processing widget %s on page %s" w env.page_file in
      if not (widget_should_run w widget settings.build_profile settings.site_dir env.page_file)
      then (process_widgets env settings ws' wh config soup) else
      let res =
        try widget.func env widget.config soup
        with Utils.Soupault_error s -> Error s
      in
      (* In non-strict mode, widget processing errors are tolerated *)
      match res, settings.strict with
      | Ok _, _ -> process_widgets env settings ws' wh config soup
      | Error _ as err, true -> err
      | Error msg, false ->
        let () = Logs.warn @@ fun m -> m "Processing widget \"%s\" failed: %s" w msg in
        process_widgets env settings ws' wh config soup
    end

(** Removes index page's parent dir from its navigation path

    When clean URLs are used, the "navigation path" as in the path
    before the page doesn'a match the "real" path for index pages,
    and if you try to use it for breadcrumbs for example,
    section index pages will have links to themselves,
    since the parent of foo/bar/index.html is technically "bar".
    The only way to deal with it I could find is to remove the
    last parent if the page is an index page.
 *)
let fix_nav_path settings path page_name =
  if page_name = settings.index_page then Utils.drop_tail path
  else path

let make_page_url settings nav_path orig_path page_file =
  let page_file_name = FP.basename page_file in
  let page =
    if settings.clean_urls then page_file_name |> FP.chop_extension
    else page_file_name
  in
  let path =
    if ((FP.chop_extension page_file_name) = settings.index_page) then orig_path
    else (List.append nav_path [page])
  in
  (* URL path should be absolute *)
  String.concat "/" path |> Printf.sprintf "/%s"

(** Decide on the page file name.

    If clean URLs are used, it's always <target_dir>/<settings.index_file>

    If clean URLs are not used, then the base file name is preserved.
    The extension, however, is set to settings.default_extension,
    unless it's in the settings.keep_extensions list.

    The reason for this extension juggling is that people may use page preprocessors
    but not use clean URLs, without extension mangling they will end up
    with pages like build/about.md that have HTML inside despit their name.
    In short, that's what Jekyll et al. always did to non-blog pages.
 *)
let make_page_file_name settings page_file target_dir =
  if settings.clean_urls then (target_dir +/ settings.index_file) else
  let page_file = FP.basename page_file in
  let extension = Utils.get_extension page_file in
  let page_file =
    if Utils.in_list settings.keep_extensions extension then page_file
    else FP.add_extension (FP.chop_extension page_file) settings.default_extension
  in target_dir +/ page_file

(** Processes a page:

    1. Adjusts the path to account for index vs non-index page difference
       in setups using clean URLs
    2. Reads a page file and inserts the content into the template,
       unless it's a complete page
    3. Updates the global index if necessary
    4. Runs the page through widgets
    5. Inserts the index section into the page if it's an index page
    6. Saves the processed page to file
  *)
let process_page page_file nav_path index widgets config settings =
  let page_name = FP.basename page_file |> FP.chop_extension in
  let target_dir = make_page_dir_name settings (Utils.concat_path nav_path) page_name |> FP.concat settings.build_dir in
  let target_file = make_page_file_name settings page_file target_dir in
  let orig_path = nav_path in
  let nav_path = fix_nav_path settings nav_path page_name in
  let page_url = make_page_url settings nav_path orig_path page_file in
  let env = {
    nav_path = nav_path;
    page_url = page_url;
    page_file = page_file;
    target_dir = target_dir;
    site_index = index;
  }
  in
  let () = Logs.info @@ fun m -> m "Processing page %s" page_file in
  let* content = load_html settings page_file in
  let* html = make_page settings page_file content in
  (* Section index injection always happens before any widgets have run *)
  let* () =
    (* Section index is inserted only in index pages *)
    if (not settings.index) || (page_name <> settings.index_page) ||
       settings.index_only  || (index = [])
    then Ok ()
    else let () = Logs.info @@ fun m -> m "Inserting section index" in
    Autoindex.insert_indices settings page_file html index
  in
  let before_index, after_index, widget_hash = widgets in
  let* () = process_widgets env settings before_index widget_hash config html in
  (* Index extraction *)
  let index_entry =
    (* Metadata is only extracted from non-index pages *)
    if (not settings.index) || (page_name = settings.index_page) ||
       not (Autoindex.index_extraction_should_run settings page_file)
    then None
    else Some (Autoindex.get_entry settings env html)
  in
  if settings.index_only then Ok index_entry else
  let* () = process_widgets env settings after_index widget_hash config html in
  let* () = mkdir target_dir in
  let* () = save_html settings html target_file in
  Ok index_entry

(* Monadic wrapper for process_page that can either return or ignore errors  *)
let _process_page index widgets config settings (page_file, nav_path) =
    let res = process_page page_file nav_path index widgets config settings in
    match res with
      Ok _ as res -> res
    | Error msg ->
      let msg = Printf.sprintf "Could not process page %s: %s" page_file msg in
      if settings.strict then Error msg else 
      let () = Logs.warn @@ fun m -> m "%s" msg in
      Ok None

(* Option parsing and initialization *)

let get_args settings =
  let init = ref false in
  let sr = ref settings in
  let args = [
    ("--init", Arg.Unit (fun () -> init := true), "Setup basic directory structure");
    ("--verbose", Arg.Unit (fun () -> sr := {!sr with verbose=true}), "Verbose output");
    ("--debug", Arg.Unit (fun () -> sr := {!sr with debug=true}), "Debug output");
    ("--strict", Arg.Bool (fun s -> sr := {!sr with strict=s}), "<true|false> Stop on page processing errors or not");
    ("--site-dir", Arg.String (fun s -> sr := {!sr with site_dir=s}), "Directory with input files");
    ("--build-dir", Arg.String (fun s -> sr := {!sr with build_dir=s}), "Output directory");
    ("--profile", Arg.String (fun s -> sr := {!sr with build_profile=(Some s)}), "Build profile");
    ("--index-only", Arg.Unit (fun () -> sr := {!sr with index_only=true}), "Extract site index without generating pages");
    ("--version", Arg.Unit (fun () -> Utils.print_version (); exit 0), "Print version and exit")
  ]
  in let usage = Printf.sprintf "Usage: %s [OPTIONS]" Sys.argv.(0) in
  let () = Arg.parse args (fun _ -> ()) usage in
  if !init then (Project_init.init !sr; exit 0) else Ok !sr

let check_project_dir settings =
  if (not (FU.test FU.Exists settings.default_template)) && settings.generator_mode
  then Logs.warn @@ fun m -> m "Default template %s does not exist" settings.default_template;
  if (not (FU.test FU.Is_dir settings.site_dir))
  then begin
    Logs.warn @@ fun m -> m "Site directory %s does not exist" settings.site_dir;
    Logs.warn @@ fun m -> m "Use %s --init to initialize a basic project" Sys.argv.(0);
    exit 1
  end

let initialize () =
  let () = Random.self_init () in
  let settings = Defaults.default_settings in
  let () = setup_logging settings.verbose settings.debug in
  let config_file =
    try Unix.getenv Defaults.config_path_env_var
    with Not_found -> Defaults.config_file
  in
  let* config = Config.read_config config_file in
  let* settings = Config.update_settings settings config in
  let* settings = get_args settings in
  (* Update the log level from the config and arguments  *)
  let () = setup_logging settings.verbose settings.debug in
  let () = check_project_dir settings in
  let* config = Ok (Toml_utils.json_of_table (config |> Option.get)) in
  let* plugins = Plugins.get_plugins (Some config) in
  let* widgets = Widgets.get_widgets settings (Some config) plugins settings.index_extract_after_widgets in
  let* default_template_str =
    if settings.generator_mode then Utils.get_file_content settings.default_template
    else Ok ""
  in
  let settings = {settings with default_template_source=default_template_str} in
  let () =
    begin
      if not settings.generator_mode then
        Logs.info @@ fun m -> m "Running in HTML processor mode, not using the page template";
      if settings.index_only && not (settings.index && (settings.dump_json <> None)) then
        Logs.warn @@ fun m -> m "--index-only is useless without index=true and dump_json options in the config!";
      if settings.build_dir = "" then
      (* Treating build_dir="" as "build in the current dir" wasn't a part of the design.
         I suppose it should be disabled in 2.0.
       *)
      Logs.warn @@ fun m -> m "Build directory is set to empty string, using current working directory for output"
    end
  in
  if settings.site_dir = "" then (Error "site_dir must be a directory path, not an empty string")
  else (Ok (config, widgets, settings))

let dump_index_json settings index =
  match settings.dump_json with
  | None -> Ok ()
  | Some f ->
    try Ok (Soup.write_file f @@ Autoindex.json_string_of_entries index)
    with Sys_error e -> Error e
  
let main () =
  let* config, widgets, settings = initialize () in
  let () = setup_logging settings.verbose settings.debug in
  let* () = make_build_dir settings.build_dir in
  let (page_files, index_files, asset_files) = Site_dir.get_site_files settings in
  (* Process normal pages and collect index data from them *)
  let* index = Utils.fold_left
    (fun acc p ->
       let ie = _process_page [] widgets config settings p in
       match ie with Ok None -> Ok acc | Ok (Some ie') -> Ok (ie' :: acc) | Error _ as err -> err)
    []
    page_files
  in
  (* Now process the index pages, using previously collected index data.
     This will produce no new index data so we ignore the non-error results. *)
  let index = Autoindex.sort_entries settings index in
  let* () = Utils.iter (_process_page index widgets config settings) index_files in
  let* () = Utils.iter (fun (src, dst) -> Utils.cp [src] dst) asset_files in
  let* () = dump_index_json settings index in
  Ok ()

let () =
  let res = main () in
  match res with
  | Ok _ -> exit 0
  | Error e ->
    Logs.err @@ fun m -> m "%s" e;
    exit 1

