open OUnit

let test_parse_personal_settings () =
  let ch = open_in "test_data/settings.xml" in
  let settings = GdataUtils.parse_xml
                   (fun () -> input_byte ch)
                   GdataCalendar.parse_personal_settings in
  let country = Hashtbl.find settings "country" in
  let customCalMode = Hashtbl.find settings "customCalMode" in
    assert_equal ~msg:"country setting" "EH" country;
    assert_equal ~msg:"customCalMode setting" "custom,14" customCalMode

let test_parse_calendar_feed () =
  let ch = open_in "test_data/all_calendars.xml" in
  let feed = GdataUtils.parse_xml
               (fun () -> input_byte ch)
               GdataCalendar.Feed.parse_feed in
    assert_equal ~msg:"feed author"
      "Coach"
      (List.hd feed.GdataCalendar.Feed.authors).GdataAtom.Author.name;
    assert_equal ~msg:"feed title"
      "Coach's Calendar List"
      feed.GdataCalendar.Feed.title.GdataAtom.Title.value

let test_parse_calendar_entry () =
  let ch = open_in "test_data/calendar_entry.xml" in
  let entry = GdataUtils.parse_xml
                (fun () -> input_byte ch)
                GdataCalendar.parse_calendar_entry in
    assert_equal ~msg:"entry title"
      "Little League Schedule"
      entry.GdataCalendar.Entry.title.GdataAtom.Title.value;
    assert_equal ~msg:"entry timezone"
      "America/Los_Angeles"
      entry.GdataCalendar.Entry.timezone

let test_parse_calendar_entry_with_extensions () =
  let ch = open_in "test_data/calendar_entry_with_extensions.xml" in
  let entry = GdataUtils.parse_xml
                (fun () -> input_byte ch)
                GdataCalendar.parse_calendar_entry in
    assert_equal
      ~printer:(fun xs ->
                  List.fold_left
                    (fun s x ->
                       s ^ (TestHelper.string_of_xml_data_model x))
                    ""
                    xs)
      [GapiCore.AnnotatedTree.Node
         ([`Element;
           `Name "new-element";
           `Namespace "http://schemas.google.com/g/2005"],
          [GapiCore.AnnotatedTree.Leaf
             ([`Attribute;
               `Name "value";
               `Namespace ""],
              "value");
           GapiCore.AnnotatedTree.Node
             ([`Element;
               `Name "new-child";
               `Namespace "http://schemas.google.com/g/2005"],
              [GapiCore.AnnotatedTree.Leaf
                 ([`Text],
                  "text")
              ])
          ])
      ]
      entry.GdataCalendar.Entry.extensions

let test_calendar_entry_to_data_model () =
  let entry =
    { GdataCalendar.Entry.empty with
          GdataCalendar.Entry.id = "id";
          authors = [
            { GdataAtom.Author.lang = "en-US";
              email = "author1@test.com";
              name = "author1";
              uri = "urn:uri";
            };
            { GdataAtom.Author.empty with
                  GdataAtom.Author.email = "author2@test.com";
                  name = "author2";
            };
          ];
          categories = [
            { GdataAtom.Category.label = "label";
              scheme = "scheme";
              term = "term";
              lang = "en-US";
            };
            { GdataAtom.Category.empty with
                  GdataAtom.Category.scheme = "scheme2";
                  term = "term2";
            }
          ];
          contributors = [
            { GdataAtom.Contributor.lang = "en-US";
              email = "contributor1@test.com";
              name = "contributor1";
              uri = "urn:uri";
            };
            { GdataAtom.Contributor.empty with
                  GdataAtom.Contributor.email = "contributor2@test.com";
                  name = "contributor2";
            };
          ];
          content =
            { GdataAtom.Content.empty with
                  GdataAtom.Content.src = "src";
            };
          published = GapiDate.of_string "2010-05-15T20:00:00.000Z";
          updated = GapiDate.of_string "2011-08-16T12:00:00.000Z";
          edited = GapiDate.of_string "2011-06-06T15:00:00.000Z";
          accesslevel = "accesslevel";
          links = [
            { GdataCalendar.Link.empty with
                  GdataCalendar.Link.href = "http://href";
                  rel = "self";
                  _type = "application/atom+xml";
            };
            { GdataCalendar.Link.href = "http://href2";
              length = Int64.of_int 10;
              rel = "alternate";
              title = "title";
              _type = "application/atom+xml";
              webContent =
                { GdataCalendar.WebContent.height = 100;
                  url = "http://webcontent";
                  width = 200;
                  webContentGadgetPrefs = [
                    { GdataCalendar.WebContentGadgetPref.name = "name";
                      value = "value";
                    };
                    { GdataCalendar.WebContentGadgetPref.name = "name2";
                      value = "value2";
                    };
                  ];
                };
            };
          ];
          where = [
            "where1";
            "where2";
          ];
          color = "#5A6986";
          hidden = true;
          selected = true;
          timezone = "America/Los_Angeles";
          timesCleaned = 1;
          summary =
            { GdataAtom.Summary.src = "src";
              _type = "type";
              lang = "en-US";
              value = "summary";
            };
          GdataCalendar.Entry.title =
            { GdataAtom.Title.empty with
                  GdataAtom.Title.value = "title";
            };
    } in
  let tree = GdataCalendar.calendar_entry_to_data_model entry in
    TestHelper.assert_equal_file
      "test_data/test_calendar_entry_to_data_model.xml"
      (GdataUtils.data_to_xml_string tree)

let test_parse_calendar_event_entry () =
  let ch = open_in "test_data/event_entry.xml" in
  let entry = GdataUtils.parse_xml
                (fun () -> input_byte ch)
                GdataCalendarEvent.parse_calendar_event_entry in
  let tree = GdataCalendarEvent.calendar_event_entry_to_data_model entry in
    TestHelper.assert_equal_file
      "test_data/test_parse_calendar_event_entry.xml"
      (GdataUtils.data_to_xml_string tree)

let test_parse_calendar_event_feed () =
  let ch = open_in "test_data/event_feed.xml" in
  let feed = GdataUtils.parse_xml
               (fun () -> input_byte ch)
               GdataCalendarEvent.Feed.parse_feed in
    assert_equal ~msg:"feed author"
      "Jo March"
      (List.hd feed.GdataCalendarEvent.Feed.authors).GdataAtom.Author.name;
    assert_equal ~msg:"feed title"
      "Jo March"
      feed.GdataCalendarEvent.Feed.title.GdataAtom.Title.value;
    assert_equal ~msg:"entry count"
      1
      (List.length feed.GdataCalendarEvent.Feed.entries)

let test_parse_acl_feed () =
  let ch = open_in "test_data/acl_feed.xml" in
  let feed = GdataUtils.parse_xml
               (fun () -> input_byte ch)
               GdataACL.Feed.parse_feed in
  let entry = List.nth feed.GdataACL.Feed.entries 1 in
    assert_equal ~msg:"feed title"
      "Elizabeth Bennet's access control list"
      feed.GdataACL.Feed.title.GdataAtom.Title.value;
    assert_equal ~msg:"entry count"
      2
      (List.length feed.GdataACL.Feed.entries);
    assert_equal ~msg:"entry scope type"
      "user"
      (entry.GdataACL.Entry.scope.GdataACL.Scope._type);
    assert_equal ~msg:"entry scope value"
      "liz@gmail.com"
      (entry.GdataACL.Entry.scope.GdataACL.Scope.value)

let test_acl_entry_to_data_model () =
  let ch = open_in "test_data/acl_feed.xml" in
  let feed = GdataUtils.parse_xml
               (fun () -> input_byte ch)
               GdataACL.Feed.parse_feed in
  let entry = List.nth feed.GdataACL.Feed.entries 1 in
  let tree = GdataACL.entry_to_data_model entry in
    TestHelper.assert_equal_file
      "test_data/test_acl_entry_to_data_model.xml"
      (GdataUtils.data_to_xml_string tree)

let test_calendar_event_batch_feed () =
  let ch = open_in "test_data/event_batch_request.xml" in
  let feed = GdataUtils.parse_xml
               (fun () -> input_byte ch)
               GdataCalendarEvent.Feed.parse_feed in
  let test_batch_id id entry =
    entry.GdataCalendarEvent.Entry.batch_id = id
  in
    TestHelper.assert_exists
      "Batch entry \"Insert itemA\" not found"
      (test_batch_id "Insert itemA")
      feed.GdataCalendarEvent.Feed.entries;
    TestHelper.assert_exists
      "Batch entry \"Query itemB\" not found"
      (test_batch_id "Query itemB")
      feed.GdataCalendarEvent.Feed.entries;
    TestHelper.assert_exists
      "Batch entry \"Update itemC\" not found"
      (test_batch_id "Update itemC")
      feed.GdataCalendarEvent.Feed.entries;
    TestHelper.assert_exists
      "Batch entry \"Delete itemD\" not found"
      (test_batch_id "Delete itemD")
      feed.GdataCalendarEvent.Feed.entries;
    assert_equal ~msg:"entry count"
      4
      (List.length feed.GdataCalendarEvent.Feed.entries)

let suite = "Calendar Model test" >:::
  ["test_parse_personal_settings" >:: test_parse_personal_settings;
   "test_parse_calendar_feed" >:: test_parse_calendar_feed;
   "test_parse_calendar_entry" >:: test_parse_calendar_entry;
   "test_parse_calendar_entry_with_extensions"
     >:: test_parse_calendar_entry_with_extensions;
   "test_calendar_entry_to_data_model" >:: test_calendar_entry_to_data_model;
   "test_parse_calendar_event_entry" >:: test_parse_calendar_event_entry;
   "test_parse_calendar_event_feed" >:: test_parse_calendar_event_feed;
   "test_parse_acl_feed" >:: test_parse_acl_feed;
   "test_acl_entry_to_data_model" >:: test_acl_entry_to_data_model;
   "test_calendar_event_batch_feed" >:: test_calendar_event_batch_feed]

