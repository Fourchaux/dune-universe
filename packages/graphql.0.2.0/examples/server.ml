open Lwt
module C = Cohttp_lwt_unix

open Graphql_lwt

type role = User | Admin

type user = {
  id   : int;
  name : string;
  role : role;
  friends : user list;
}

let rec alice = { id = 1; name = "Alice"; role = Admin; friends = [bob] }
and bob = { id = 2; name = "Bob"; role = User; friends = [alice]}

let users = [alice; bob]

let role = Schema.(enum "role"
  ~values:[
    enum_value "USER" ~value:User ~doc:"A regular user";
    enum_value "ADMIN" ~value:Admin ~doc:"An admin user";
  ]
)

let user = Schema.(obj "user"
  ~fields:(fun user -> [
    field "id"
      ~args:Arg.[]
      ~typ:(non_null int)
      ~resolve:(fun () p -> p.id)
    ;
    field "name"
      ~args:Arg.[]
      ~typ:(non_null string)
      ~resolve:(fun () p -> p.name)
    ;
    field "role"
      ~args:Arg.[]
      ~typ:(non_null role)
      ~resolve:(fun () p -> p.role)
    ;
    field "friends"
      ~args:Arg.[]
      ~typ:(list (non_null user))
      ~resolve:(fun () p -> Some p.friends)
  ])
)

let schema = Schema.(schema [
    io_field "users"
      ~args:Arg.[]
      ~typ:(non_null (list (non_null user)))
      ~resolve:(fun () () -> Lwt.return users)
    ;
    field "greeter"
      ~typ:string
      ~args:Arg.[
        arg "config" ~typ:(non_null (obj "greeter_config" ~coerce:(fun greeting name -> (greeting, name)) ~fields:[
          arg' "greeting" ~typ:string ~default:"hello";
          arg "name" ~typ:(non_null string)
        ]))
      ]
      ~resolve:(fun () () (greeting, name) ->
        Some (Format.sprintf "%s, %s" greeting name)
      )
    ;
  ]
)

let json_err = function
  | Ok _ as ok -> ok
  | Error err -> Error (`String err)

let execute variables query =
  let open Lwt_result in
  Lwt.return @@ json_err @@ Graphql_parser.parse query >>= fun doc ->
  Schema.execute schema () ~variables doc

let callback conn (req : Cohttp.Request.t) body =
  Lwt_io.printf "Req: %s\n" req.resource;
  match (req.meth, req.resource) with
  | `GET, _ -> C.Server.respond_file "./index.html" ()
  | `POST, _ ->
    begin
      Cohttp_lwt_body.to_string body >>= fun query_json ->
      Lwt_io.printf "Body: %s\n" query_json;
      let query = Yojson.Basic.(from_string query_json |> Util.member "query" |> Util.to_string)
      in
      let variables =
        try
          Yojson.Basic.(from_string query_json |> Util.member "variables" |> Util.to_assoc)
        with _ -> []
      in
      Lwt_io.printf "Query: %s\n" query;
      execute (variables :> (string * Graphql_parser.const_value) list) query >>= function
      | Ok data ->
          let body = Yojson.Basic.to_string data in
          C.Server.respond_string ~status:`OK ~body ()
      | Error err ->
          let body = Yojson.Basic.to_string err in
          C.Server.respond_error ~body ()
    end
  | _ -> C.Server.respond_string ~status:`Not_found ~body:"" ()

let () =
  C.Server.create ~mode:(`TCP (`Port 8080)) (C.Server.make ~callback ())
  |> Lwt_main.run
