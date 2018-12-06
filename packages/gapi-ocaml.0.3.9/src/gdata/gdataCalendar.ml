open GapiUtils.Infix

(* Calendar data types *)
let ns_gCal = "http://schemas.google.com/gCal/2005"

type calendar_accessLevelProperty = string

type calendar_colorProperty = string

type calendar_hiddenProperty = bool

type calendar_overrideNameProperty = string

type calendar_selectedProperty = bool

type calendar_timeZoneProperty = string

type calendar_timesCleanedProperty = int

type gdata_attendeeStatus = string

type gdata_eventStatus = string

type calendar_icalUIDProperty = string

type calendar_privateCopyProperty = bool

type calendar_quickAddProperty = bool

type gdata_recurrence = string

type calendar_sendEventNotificationsProperty = bool

type calendar_sequenceNumberProperty = int

type calendar_syncEventProperty = bool

type gdata_transparency = string

type gdata_visibility = string

module WebContentGadgetPref =
struct
  type t = {
    name : string;
    value : string;
  }

  let empty = {
    name = "";
    value = ""
  }

  let to_xml_data_model webContentGadgetPref =
    GdataAtom.render_element ns_gCal "webContentGadgetPref"
      [GdataAtom.render_attribute "" "name" webContentGadgetPref.name;
       GdataAtom.render_attribute "" "value" webContentGadgetPref.value]

  let of_xml_data_model wcgp tree =
    match tree with
        GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "name"; `Namespace ""],
           v) ->
          { wcgp with name = v }
      | GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "value"; `Namespace ""],
           v) ->
          { wcgp with value = v }
      | e ->
          GdataUtils.unexpected e

end

module WebContent =
struct
  type t = {
    height : int;
    url : string;
    width : int;
    webContentGadgetPrefs : WebContentGadgetPref.t list
  }

  let empty = {
    height = 0;
    url = "";
    width = 0;
    webContentGadgetPrefs = []
  }

  let to_xml_data_model webContent =
    GdataAtom.render_element ns_gCal "webContent"
      [GdataAtom.render_int_attribute "" "height" webContent.height;
       GdataAtom.render_attribute "" "url" webContent.url;
       GdataAtom.render_int_attribute "" "width" webContent.width;
       GdataAtom.render_element_list WebContentGadgetPref.to_xml_data_model webContent.webContentGadgetPrefs]

  let of_xml_data_model webContent tree =
    match tree with
        GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "height"; `Namespace ""],
           v) ->
          { webContent with height = int_of_string v }
      | GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "url"; `Namespace ""],
           v) ->
          { webContent with url = v }
      | GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "width"; `Namespace ""],
           v) ->
          { webContent with width = int_of_string v }
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "webContentGadgetPref"; `Namespace ns],
           cs) when ns = ns_gCal ->
          GdataAtom.parse_children
            WebContentGadgetPref.of_xml_data_model
            WebContentGadgetPref.empty
            (fun wcgp -> { webContent with webContentGadgetPrefs =
                             wcgp :: webContent.webContentGadgetPrefs })
            cs
      | e ->
          GdataUtils.unexpected e

end

module ResourceProperty =
struct
  type t = {
    id : string;
    value : bool
  }

  let empty = {
    id = "";
    value = false
  }

  let to_xml_data_model property =
    GdataAtom.render_element GdataAtom.ns_gd "resource"
      [GdataAtom.render_attribute "" "id" property.id;
       GdataAtom.render_attribute "" "value" (string_of_bool property.value)]

  let of_xml_data_model resource tree =
    match tree with
        GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "id"; `Namespace ns],
           v) when ns = "" ->
          { resource with id = v }
      | GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "value"; `Namespace ns],
           v) when ns = "" ->
          { resource with value = bool_of_string v }
      | e ->
          GdataUtils.unexpected e

end

module Who =
struct
  type t = {
    email : string;
    rel : string;
    value : string;
    resource : ResourceProperty.t;
    attendeeStatus : gdata_attendeeStatus
  }

  let empty = {
    email = "";
    rel = "";
    value = "";
    resource = ResourceProperty.empty;
    attendeeStatus = ""
  }

  let to_xml_data_model who =
    let render_attendeeStatus status =
      GdataAtom.render_value ~attribute:"value" GdataAtom.ns_gd "who" status
    in
      GdataAtom.render_element GdataAtom.ns_gd "resource"
        [GdataAtom.render_attribute "" "email" who.email;
         GdataAtom.render_attribute "" "rel" who.rel;
         GdataAtom.render_attribute "" "valueString" who.value;
         ResourceProperty.to_xml_data_model who.resource;
         render_attendeeStatus who.attendeeStatus]

  let of_xml_data_model who tree =
    let parse_attendeeStatus _ tree =
      match tree with
          GapiCore.AnnotatedTree.Leaf
            ([`Attribute; `Name "value"; `Namespace ""],
             v) ->
            v
        | e ->
            GdataUtils.unexpected e
    in
      match tree with
          GapiCore.AnnotatedTree.Leaf
            ([`Attribute; `Name "email"; `Namespace ns],
             v) when ns = "" ->
            { who with email = v }
        | GapiCore.AnnotatedTree.Leaf
            ([`Attribute; `Name "rel"; `Namespace ns],
             v) when ns = "" ->
            { who with rel = v }
        | GapiCore.AnnotatedTree.Leaf
            ([`Attribute; `Name "valueString"; `Namespace ns],
             v) when ns = "" ->
            { who with value = v }
        | GapiCore.AnnotatedTree.Node
            ([`Element; `Name "resource"; `Namespace ns],
             cs) when ns = ns_gCal ->
            GdataAtom.parse_children
              ResourceProperty.of_xml_data_model
              ResourceProperty.empty
              (fun property -> { who with resource = property })
              cs
        | GapiCore.AnnotatedTree.Node
            ([`Element; `Name "attendeeStatus"; `Namespace ns],
             cs) when ns = GdataAtom.ns_gd ->
            GdataAtom.parse_children
              parse_attendeeStatus
              ""
              (fun status -> { who with attendeeStatus = status })
              cs
        | e ->
            GdataUtils.unexpected e

end

module Reminder =
struct
  type t = {
    absoluteTime : GapiDate.t;
    days : int;
    hours : int;
    rmethod : string;
    minutes : int
  }

  let empty = {
    absoluteTime = GapiDate.epoch;
    days = 0;
    hours = 0;
    rmethod = "";
    minutes = 0
  }

  let to_xml_data_model reminder =
    GdataAtom.render_element GdataAtom.ns_gd "reminder"
      [GdataAtom.render_date_attribute "" "absoluteTime" reminder.absoluteTime;
       GdataAtom.render_attribute "" "days" (string_of_int reminder.days);
       GdataAtom.render_attribute "" "hours" (string_of_int reminder.hours);
       GdataAtom.render_attribute "" "method" reminder.rmethod;
       GdataAtom.render_attribute "" "minutes" (string_of_int reminder.minutes)]

  let of_xml_data_model reminder tree =
    match tree with
        GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "absoluteTime"; `Namespace ns],
           v) when ns = "" ->
          { reminder with absoluteTime = GapiDate.of_string v }
      | GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "days"; `Namespace ns],
           v) when ns = "" ->
          { reminder with days = int_of_string v }
      | GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "hours"; `Namespace ns],
           v) when ns = "" ->
          { reminder with hours = int_of_string v }
      | GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "method"; `Namespace ns],
           v) when ns = "" ->
          { reminder with rmethod = v }
      | GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "minutes"; `Namespace ns],
           v) when ns = "" ->
          { reminder with minutes = int_of_string v }
      | e ->
          GdataUtils.unexpected e

end

module When =
struct
  type t = {
    endTime : GapiDate.t;
    startTime : GapiDate.t;
    value : string;
    reminders : Reminder.t list
  }

  let empty = {
    endTime = GapiDate.epoch;
    startTime = GapiDate.epoch;
    value = "";
    reminders = []
  }

  let to_xml_data_model cwhen =
    GdataAtom.render_element GdataAtom.ns_gd "when"
      [GdataAtom.render_date_attribute "" "startTime" cwhen.startTime;
       GdataAtom.render_date_attribute "" "endTime" cwhen.endTime;
       GdataAtom.render_attribute "" "valueString" cwhen.value;
       GdataAtom.render_element_list Reminder.to_xml_data_model cwhen.reminders]

  let of_xml_data_model cwhen tree =
    match tree with
        GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "startTime"; `Namespace ns],
           v) when ns = "" ->
          { cwhen with startTime = GapiDate.of_string v }
      | GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "endTime"; `Namespace ns],
           v) when ns = "" ->
          { cwhen with endTime = GapiDate.of_string v }
      | GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "valueString"; `Namespace ns],
           v) when ns = "" ->
          { cwhen with value = v }
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "reminder"; `Namespace ns],
           cs) when ns = GdataAtom.ns_gd ->
          GdataAtom.parse_children
            Reminder.of_xml_data_model
            Reminder.empty
            (fun reminder ->
               { cwhen with reminders = reminder :: cwhen.reminders })
            cs
      | e ->
          GdataUtils.unexpected e

end

module OriginalEvent =
struct
  type t = {
    href : string;
    id : string;
    _when : When.t
  }

  let empty = {
    href = "";
    id = "";
    _when = When.empty
  }

  let to_xml_data_model event =
    GdataAtom.render_element GdataAtom.ns_gd "originalEvent"
      [GdataAtom.render_attribute "" "href" event.href;
       GdataAtom.render_attribute "" "id" event.id;
       When.to_xml_data_model event._when]

  let of_xml_data_model event tree =
    match tree with
        GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "href"; `Namespace ns],
           v) when ns = "" ->
          { event with href = v }
      | GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "id"; `Namespace ns],
           v) when ns = "" ->
          { event with id = v }
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "when"; `Namespace ns],
           cs) when ns = GdataAtom.ns_gd ->
          GdataAtom.parse_children
            When.of_xml_data_model
            When.empty
            (fun cwhen -> { event with _when = cwhen })
            cs
      | e ->
          GdataUtils.unexpected e

end

module ExtendedProperty =
struct
  type t = {
    cep_name : string;
    cep_realm : string;
    cep_value : string
  }

  let empty = {
    cep_name = "";
    cep_realm = "";
    cep_value = ""
  }

  let to_xml_data_model property =
    GdataAtom.render_element GdataAtom.ns_gd "extendedProperty"
      [GdataAtom.render_attribute "" "name" property.cep_name;
       GdataAtom.render_attribute "" "realm" property.cep_realm;
       GdataAtom.render_attribute "" "value" property.cep_value]

  let of_xml_data_model property tree =
    match tree with
        GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "name"; `Namespace ns],
           v) when ns = "" ->
          { property with cep_name = v }
      | GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "realm"; `Namespace ns],
           v) when ns = "" ->
          { property with cep_realm = v }
      | GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "value"; `Namespace ns],
           v) when ns = "" ->
          { property with cep_value = v }
      | e ->
          GdataUtils.unexpected e

end

module Where =
struct
  type t = string

  let empty = ""

  let to_xml_data_model where =
    GdataAtom.render_value ~attribute:"valueString" GdataAtom.ns_gd "where" where

  let of_xml_data_model where tree =
    match tree with
        GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "valueString"; `Namespace ""],
           v) ->
          v
      | e ->
          GdataUtils.unexpected e

end

module Link =
struct
  type t = {
    href : string;
    length : Int64.t;
    rel : string;
    title : string;
    _type : string;
    webContent : WebContent.t
  }

  let empty = {
    href = "";
    length = 0L;
    rel = "";
    title = "";
    _type = "";
    webContent = WebContent.empty
  }

  let to_xml_data_model link =
    GdataAtom.render_element GdataAtom.ns_atom "link"
      [GdataAtom.render_attribute "" "href" link.href;
       GdataAtom.render_generic_attribute Int64.to_string Int64.zero "" "length" link.length;
       GdataAtom.render_attribute "" "rel" link.rel;
       GdataAtom.render_attribute "" "title" link.title;
       GdataAtom.render_attribute "" "type" link._type;
       WebContent.to_xml_data_model link.webContent]

  let of_xml_data_model link tree =
    match tree with
        GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "href"; `Namespace ""],
           v) ->
          { link with href = v }
      | GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "length"; `Namespace ""],
           v) ->
          { link with length = Int64.of_string v }
      | GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "rel"; `Namespace ""],
           v) ->
          { link with rel = v }
      | GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "title"; `Namespace ""],
           v) ->
          { link with title = v }
      | GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "type"; `Namespace ""],
           v) ->
          { link with _type = v }
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "webContent"; `Namespace ns],
           cs) when ns = ns_gCal ->
          GdataAtom.parse_children
            WebContent.of_xml_data_model
            WebContent.empty
            (fun webContent -> { link with webContent })
            cs
      | e ->
          GdataUtils.unexpected e

end

module Entry =
struct
  type t = {
    etag : string;
    kind : string;
    authors : GdataAtom.Author.t list;
    categories : GdataAtom.Category.t list;
    contributors : GdataAtom.Contributor.t list;
    id : GdataAtom.atom_id;
    content : GdataAtom.Content.t;
    published : GdataAtom.atom_published;
    updated : GdataAtom.atom_updated;
    edited : GdataAtom.app_edited;
    accesslevel : calendar_accessLevelProperty;
    links : Link.t list;
    where : Where.t list;
    color : calendar_colorProperty;
    hidden : calendar_hiddenProperty;
    overridename : calendar_overrideNameProperty;
    selected : calendar_selectedProperty;
    timezone : calendar_timeZoneProperty;
    timesCleaned : calendar_timesCleanedProperty;
    summary : GdataAtom.Summary.t;
    title : GdataAtom.Title.t;
    extensions : GdataCore.xml_data_model list
  }

  let empty = {
    etag = "";
    kind = "";
    authors = [];
    categories = [];
    contributors = [];
    id = "";
    content = GdataAtom.Content.empty;
    published = GapiDate.epoch;
    updated = GapiDate.epoch;
    edited = GapiDate.epoch;
    accesslevel = "";
    links = [];
    where = [];
    color = "";
    hidden = false;
    overridename = "";
    selected = false;
    timezone = "";
    timesCleaned = 0;
    summary = GdataAtom.Summary.empty;
    title = GdataAtom.Title.empty;
    extensions = []
  }

  let to_xml_data_model entry =
    GdataAtom.render_element GdataAtom.ns_atom "entry"
      [GdataAtom.render_attribute GdataAtom.ns_gd "etag" entry.etag;
       GdataAtom.render_attribute GdataAtom.ns_gd "kind" entry.kind;
       GdataAtom.render_element_list GdataAtom.Author.to_xml_data_model entry.authors;
       GdataAtom.render_element_list GdataAtom.Category.to_xml_data_model entry.categories;
       GdataAtom.render_element_list GdataAtom.Contributor.to_xml_data_model entry.contributors;
       GdataAtom.render_text_element GdataAtom.ns_atom "id" entry.id;
       GdataAtom.Content.to_xml_data_model entry.content;
       GdataAtom.render_date_element GdataAtom.ns_atom "published" entry.published;
       GdataAtom.render_date_element GdataAtom.ns_atom "updated" entry.updated;
       GdataAtom.render_date_element GdataAtom.ns_app "edited" entry.edited;
       GdataAtom.render_value ns_gCal "accesslevel" entry.accesslevel;
       GdataAtom.render_element_list Link.to_xml_data_model entry.links;
       GdataAtom.render_element_list Where.to_xml_data_model entry.where;
       GdataAtom.render_value ns_gCal "color" entry.color;
       GdataAtom.render_bool_value ns_gCal "hidden" entry.hidden;
       GdataAtom.render_bool_value ns_gCal "selected" entry.selected;
       GdataAtom.render_value ns_gCal "timezone" entry.timezone;
       GdataAtom.render_int_value ns_gCal "timesCleaned" entry.timesCleaned;
       GdataAtom.Summary.to_xml_data_model entry.summary;
       GdataAtom.Title.to_xml_data_model entry.title;
       entry.extensions]

  let of_xml_data_model entry tree =
    match tree with
        GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "etag"; `Namespace ns],
           v) when ns = GdataAtom.ns_gd ->
          { entry with etag = v }
      | GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name "kind"; `Namespace ns],
           v) when ns = GdataAtom.ns_gd ->
          { entry with kind = v }
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "author"; `Namespace ns],
           cs) when ns = GdataAtom.ns_atom ->
          GdataAtom.parse_children
            GdataAtom.Author.of_xml_data_model
            GdataAtom.Author.empty
            (fun author -> { entry with authors = author :: entry.authors })
            cs
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "category"; `Namespace ns],
           cs) when ns = GdataAtom.ns_atom ->
          GdataAtom.parse_children
            GdataAtom.Category.of_xml_data_model
            GdataAtom.Category.empty
            (fun category -> { entry with categories = category :: entry.categories })
            cs
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "contributor"; `Namespace ns],
           cs) when ns = GdataAtom.ns_atom ->
          GdataAtom.parse_children
            GdataAtom.Contributor.of_xml_data_model
            GdataAtom.Contributor.empty
            (fun contributor -> { entry with contributors =
                                    contributor :: entry.contributors })
            cs
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "id"; `Namespace ns],
           [GapiCore.AnnotatedTree.Leaf
              ([`Text], v)]) when ns = GdataAtom.ns_atom ->
          { entry with id = v }
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "content"; `Namespace ns],
           cs) when ns = GdataAtom.ns_atom ->
          GdataAtom.parse_children
            GdataAtom.Content.of_xml_data_model
            GdataAtom.Content.empty
            (fun content -> { entry with content })
            cs
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "published"; `Namespace ns],
           [GapiCore.AnnotatedTree.Leaf
              ([`Text], v)]) when ns = GdataAtom.ns_atom ->
          { entry with published = GapiDate.of_string v }
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "updated"; `Namespace ns],
           [GapiCore.AnnotatedTree.Leaf
              ([`Text], v)]) when ns = GdataAtom.ns_atom ->
          { entry with updated = GapiDate.of_string v }
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "edited"; `Namespace ns],
           [GapiCore.AnnotatedTree.Leaf
              ([`Text], v)]) when ns = GdataAtom.ns_app ->
          { entry with edited = GapiDate.of_string v }
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "accesslevel"; `Namespace ns],
           [GapiCore.AnnotatedTree.Leaf
              ([`Attribute; `Name "value"; `Namespace ""],
               v)]) when ns = ns_gCal ->
          { entry with accesslevel = v }
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "link"; `Namespace ns],
           cs) when ns = GdataAtom.ns_atom ->
          GdataAtom.parse_children
            Link.of_xml_data_model
            Link.empty
            (fun link -> { entry with links = link :: entry.links })
            cs
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "where"; `Namespace ns],
           cs) when ns = GdataAtom.ns_gd ->
          GdataAtom.parse_children
            Where.of_xml_data_model
            Where.empty 
            (fun where -> { entry with where = where :: entry.where })
            cs
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "color"; `Namespace ns],
           [GapiCore.AnnotatedTree.Leaf
              ([`Attribute; `Name "value"; `Namespace ""],
               v)]) when ns = ns_gCal ->
          { entry with color = v }
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "hidden"; `Namespace ns],
           [GapiCore.AnnotatedTree.Leaf
              ([`Attribute; `Name "value"; `Namespace ""],
               v)]) when ns = ns_gCal ->
          { entry with hidden = bool_of_string v }
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "overridename"; `Namespace ns],
           [GapiCore.AnnotatedTree.Leaf
              ([`Attribute; `Name "value"; `Namespace ""],
               v)]) when ns = ns_gCal ->
          { entry with overridename = v }
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "selected"; `Namespace ns],
           [GapiCore.AnnotatedTree.Leaf
              ([`Attribute; `Name "value"; `Namespace ""],
               v)]) when ns = ns_gCal ->
          { entry with selected = bool_of_string v }
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "timezone"; `Namespace ns],
           [GapiCore.AnnotatedTree.Leaf
              ([`Attribute; `Name "value"; `Namespace ""],
               v)]) when ns = ns_gCal ->
          { entry with timezone = v }
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "timesCleaned"; `Namespace ns],
           [GapiCore.AnnotatedTree.Leaf
              ([`Attribute; `Name "value"; `Namespace ""],
               v)]) when ns = ns_gCal ->
          { entry with timesCleaned = int_of_string v }
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "summary"; `Namespace ns],
           cs) when ns = GdataAtom.ns_atom ->
          GdataAtom.parse_children
            GdataAtom.Summary.of_xml_data_model
            GdataAtom.Summary.empty
            (fun summary -> { entry with summary })
            cs
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "title"; `Namespace ns],
           cs) when ns = GdataAtom.ns_atom ->
          GdataAtom.parse_children
            GdataAtom.Title.of_xml_data_model
            GdataAtom.Title.empty
            (fun title -> { entry with title })
            cs
      | GapiCore.AnnotatedTree.Leaf
          ([`Attribute; `Name _; `Namespace ns],
           _) when ns = Xmlm.ns_xmlns ->
          entry
      | extension ->
          let extensions = extension :: entry.extensions in
            { entry with extensions }

end

module Feed =
  GdataAtom.MakeFeed(Entry)(Link)(GdataAtom.GenericExtensions)

module Comments = GdataComments.Make(Link)
(* END Calendar data types *)

(* Personal settings *)
let parse_personal_settings tree =
  let settings = Hashtbl.create 16 in

  let parse_entry tree =
    match tree with
        GapiCore.AnnotatedTree.Node
          ([`Element; `Name "settingsProperty"; `Namespace ns],
           [GapiCore.AnnotatedTree.Leaf
              ([`Attribute; `Name "name"; `Namespace ""],
               n);
            GapiCore.AnnotatedTree.Leaf
              ([`Attribute; `Name "value"; `Namespace ""],
               v)]) when ns = ns_gCal ->
          Hashtbl.add settings n v
      | _ ->
          ()
  in

  let parse_feed tree =
    match tree with
      | GapiCore.AnnotatedTree.Node
          ([`Element; `Name "entry"; `Namespace ns],
           cs) when ns = GdataAtom.ns_atom ->
          List.iter parse_entry cs
      | _ ->
          ()
  in

  let parse_root tree =
    match tree with
        GapiCore.AnnotatedTree.Node
          ([`Element; `Name "feed"; `Namespace ns],
           cs) when ns = GdataAtom.ns_atom ->
          List.iter parse_feed cs
      | e ->
          GdataUtils.unexpected e
  in
    parse_root tree;
    settings
(* END Personal settings *)

(* Utilities *)
let get_calendar_prefix namespace =
  if namespace = ns_gCal then "gCal"
  else GdataACL.get_acl_prefix namespace

let parse_calendar_entry =
  GdataAtom.data_model_to_entry Entry.of_xml_data_model Entry.empty

let calendar_entry_to_data_model =
  GdataAtom.element_to_data_model get_calendar_prefix Entry.to_xml_data_model

module Rel =
struct
  type t =
    [ `EventFeed
    | GdataACL.Rel.t ]

  let to_string l  =
    match l with
        `EventFeed -> ns_gCal ^ "#eventFeed"
      | #GdataACL.Rel.t -> GdataACL.Rel.to_string l

end

let find_url rel links =
  let link = List.find
               (fun link ->
                  link.Link.rel = Rel.to_string rel)
               links
  in
    link.Link.href
(* END Utilities *)

