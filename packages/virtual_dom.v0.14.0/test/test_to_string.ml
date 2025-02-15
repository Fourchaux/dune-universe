open! Core_kernel
open! Import

let show node =
  let t = node |> Node_helpers.unsafe_convert_exn in
  t |> [%sexp_of: Node_helpers.t] |> print_s;
  print_endline "----------------------";
  t |> Node_helpers.to_string_html |> print_endline
;;

let%expect_test "basic text" =
  show (Node.text "hello");
  [%expect {|
    (Text hello)
    ----------------------
    hello |}]
;;

let%expect_test "empty div" =
  show (Node.div [] []);
  [%expect
    {|
    (Element (tag_name div))
    ----------------------
    <div> </div> |}]
;;

let%expect_test "div with some text" =
  show (Node.div [] [ Node.text "hello world" ]);
  [%expect
    {|
    (Element (tag_name div) (children ((Text "hello world"))))
    ----------------------
    <div> hello world </div> |}]
;;

let%expect_test "empty div with key" =
  show (Node.div ~key:"keykey" [] []);
  [%expect
    {|
    (Element (tag_name div) (key keykey))
    ----------------------
    <div @key=keykey> </div> |}]
;;

let%expect_test "empty div with string property" =
  show (Node.div [ Attr.string_property "foo" "bar" ] []);
  [%expect
    {|
    (Element (tag_name div) (string_properties ((foo bar))))
    ----------------------
    <div #foo="bar"> </div> |}]
;;

let%expect_test "nested div with span" =
  show (Node.div [] [ Node.span [] [] ]);
  [%expect
    {|
    (Element (tag_name div) (children ((Element (tag_name span)))))
    ----------------------
    <div>
      <span> </span>
    </div> |}]
;;

let%expect_test "empty div with string attribute" =
  show (Node.div [ Attr.create "key" "value" ] []);
  [%expect
    {|
    (Element (tag_name div) (attributes ((key value))))
    ----------------------
    <div key="value"> </div> |}]
;;

let%expect_test "empty div with float attribute" =
  show (Node.div [ Attr.create_float "some_attr" 1.2345 ] []);
  [%expect
    {|
    (Element (tag_name div) (attributes ((some_attr 1.2345))))
    ----------------------
    <div some_attr="1.2345"> </div> |}]
;;

let%expect_test "widget" =
  let widget =
    Node.widget
      ~id:(Type_equal.Id.create ~name:"name_goes_here" [%sexp_of: opaque])
      ~init:(fun _ -> failwith "unreachable")
      ()
  in
  show widget;
  [%expect
    {|
    (Widget name_goes_here)
    ----------------------
    <widget id=name_goes_here /> |}]
;;

let%expect_test "empty div with callback" =
  show (Node.div [ Attr.on_click (Fn.const Event.Ignore) ] []);
  [%expect
    {|
    (Element (tag_name div) (handlers ((onclick <handler>))))
    ----------------------
    <div onclick={handler}> </div> |}]
;;

let%expect_test "empty div with class list" =
  show (Node.div [ Attr.classes [ "a"; "b"; "c" ] ] []);
  [%expect
    {|
    (Element (tag_name div) (attributes ((class "a b c"))))
    ----------------------
    <div class="a b c"> </div> |}]
;;

let%expect_test "empty div with id" =
  show (Node.div [ Attr.id "my-id" ] []);
  [%expect
    {|
    (Element (tag_name div) (attributes ((id my-id))))
    ----------------------
    <div id="my-id"> </div> |}]
;;
