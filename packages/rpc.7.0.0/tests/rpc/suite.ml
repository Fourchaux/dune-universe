let () =
  Alcotest.run "rpc tests"
    [ ("Client_async_new", Client_async_new.tests)
    ; ("Client_lwt_new", Client_lwt_new.tests)
    ; ("Client_new", Client_new.tests)
    ; ("Test_pythongen", Test_pythongen.tests) ]
