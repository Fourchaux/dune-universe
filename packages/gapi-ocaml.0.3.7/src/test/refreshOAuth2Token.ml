let _ =
  TestHelper.test_request_noauth
    (fun test_config session ->
       let get = Config.get test_config in
       let client_id = get "oa2_id" in
       let client_secret = get "oa2_secret" in
       let refresh_token = get "oa2_refresh" in
       let (response, _) =
         GapiOAuth2.refresh_access_token
           ~client_id
           ~client_secret
           ~refresh_token
           session
       in
         match response with
             GapiAuthResponse.OAuth2AccessToken token ->
               Config.set
                 test_config
                 "oa2_token"
                 token.GapiAuthResponse.OAuth2.access_token;
               Config.save test_config
           | _ -> failwith "Not supported OAuth2 response")

