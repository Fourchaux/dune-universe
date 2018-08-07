open Idl

type lwt_rpcfn = Rpc.call -> Rpc.response Lwt.t

(* Construct a helper monad to hide the nasty 'a comp type *)
module M = struct
  type 'a lwt = { lwt: 'a Lwt.t }
  type ('a, 'b) t = ('a, 'b) Result.result lwt

  let return x = { lwt=Lwt.return (Result.Ok x) }
  let return_err e = { lwt=Lwt.return (Result.Error e)}
  let checked_bind x f f1 = { lwt=Lwt.bind x.lwt (function | Result.Ok x -> (f x).lwt | Result.Error x -> (f1 x).lwt) }
  let bind x f = checked_bind x f return_err
  let (>>=) x f = bind x f
  let lwt x = x.lwt
end

module GenClient () = struct
  type implementation = unit

  let description = ref None

  let implement x = description := Some x

  type ('a,'b) comp = ('a,'b) Result.result M.lwt
  type rpcfn = Rpc.call -> Rpc.response Lwt.t
  type 'a res = rpcfn -> 'a

  type _ fn =
    | Function : 'a Param.t * 'b fn -> ('a -> 'b) fn
    | Returning : ('a Param.t * 'b Idl.Error.t) -> ('a, 'b) M.t fn

  let returning a err = Returning (a, err)
  let (@->) = fun t f -> Function (t, f)

  let declare name _ ty (rpc : rpcfn) =
    let open Result in
    let rec inner : type b. ((string * Rpc.t) list option * Rpc.t list) -> b fn -> b = fun (named,unnamed) ->
      function
      | Function (t, f) -> begin
          let cur_named = match named with | Some n -> n | None -> [] in
          fun v ->
            match t.Param.name with
            | Some n -> begin
                match t.Param.typedef.Rpc.Types.ty, v with
                | Rpc.Types.Option _, None ->
                  inner (Some cur_named, unnamed) f
                | Rpc.Types.Option t1, Some v' ->
                  let marshalled = Rpcmarshal.marshal t1 v' in
                  inner (Some ((n, marshalled)::cur_named),unnamed) f
                | ty, v ->
                  let marshalled = Rpcmarshal.marshal ty v in
                  inner (Some ((n, marshalled)::cur_named),unnamed) f
              end
            | None ->
              let marshalled = Rpcmarshal.marshal t.Param.typedef.Rpc.Types.ty v in
              inner (named,(marshalled::unnamed)) f
        end
      | Returning (t, e) ->
        let wire_name = get_wire_name !description name in
        let args =
          match named with
          | None -> List.rev unnamed
          | Some l -> (Rpc.Dict l) :: List.rev unnamed
        in
        let call = Rpc.call wire_name args in
        let res = Lwt.bind (rpc call) (fun r ->
            if r.Rpc.success
            then match Rpcmarshal.unmarshal t.Param.typedef.Rpc.Types.ty r.Rpc.contents with Ok x -> Lwt.return (Ok x) | Error (`Msg x) -> Lwt.fail (MarshalError x)
            else match Rpcmarshal.unmarshal e.Idl.Error.def.Rpc.Types.ty r.Rpc.contents with Ok x -> Lwt.return (Error x) | Error (`Msg x) -> Lwt.fail (MarshalError x)) in
        {M.lwt=res}
    in inner (None,[]) ty
end

exception UnknownMethod of string
exception UnboundImplementation of string list

type server_implementation = (string, lwt_rpcfn option) Hashtbl.t

let server hashtbl =
  let impl = Hashtbl.create (Hashtbl.length hashtbl) in
  let unbound_impls = Hashtbl.fold (fun key fn acc ->
      match fn with
      | None -> key::acc
      | Some fn -> Hashtbl.add impl key fn; acc
    ) hashtbl [] in
  if unbound_impls <> [] then
    raise (UnboundImplementation unbound_impls);
  fun call ->
    let fn = try Hashtbl.find impl call.Rpc.name with Not_found -> raise (UnknownMethod call.Rpc.name) in
    fn call

let combine hashtbls =
  let result = Hashtbl.create 16 in
  List.iter (Hashtbl.iter (fun k v -> Hashtbl.add result k v)) hashtbls;
  result

module GenServer () = struct
  open Rpc

  let funcs = Hashtbl.create 20

  type implementation = server_implementation

  let description = ref None
  let implement x = description := Some x; funcs

  type ('a,'b) comp = ('a,'b) Result.result M.lwt
  type 'a res = 'a -> unit

  type _ fn =
    | Function : 'a Param.t * 'b fn -> ('a -> 'b) fn
    | Returning : ('a Param.t * 'b Idl.Error.t) -> ('a, 'b) M.t fn

  let returning a b = Returning (a,b)
  let (@->) = fun t f -> Function (t, f)

  let rec has_named_args : type a. a fn -> bool =
    function
    | Function (t, f) -> begin
        match t.Param.name with
        | Some _ -> true
        | None -> has_named_args f
      end
    | Returning (_, _) ->
      false

  let declare : string -> string list -> 'a fn -> 'a res = fun name _ ty ->
    (* We do not know the wire name yet as the description may still be unset *)
    Hashtbl.add funcs name None;
    fun impl ->
      begin
        (* Sanity check: ensure the description has been set before we declare
           any RPCs *)
        match !description with
        | Some _ -> ()
        | None -> raise Idl.NoDescription
      end;
      let rpcfn =
        let has_named = has_named_args ty in
        let rec inner : type a. a fn -> a -> call -> response Lwt.t = fun f impl call ->
          match f with
          | Function (t, f) -> begin
              let is_opt = match t.Param.typedef.Rpc.Types.ty with | Rpc.Types.Option _ -> true | _ -> false in
              let (arg_rpc, call') =
                match get_arg call has_named t.Param.name is_opt with
                | Result.Ok (x,y) -> (x,y)
                | Result.Error (`Msg m) -> raise (MarshalError m)
              in
              let z = Rpcmarshal.unmarshal t.Param.typedef.Rpc.Types.ty arg_rpc in
              match z with
              | Result.Ok arg -> inner f (impl arg) call'
              | Result.Error (`Msg m) -> Lwt.fail (MarshalError m)
            end
          | Returning (t,e) -> begin
              Lwt.bind impl.M.lwt (function
                  | Result.Ok x -> Lwt.return (success (Rpcmarshal.marshal t.Param.typedef.Rpc.Types.ty x))
                  | Result.Error y -> Lwt.return (failure (Rpcmarshal.marshal e.Idl.Error.def.Rpc.Types.ty y)))
            end
        in inner ty impl
      in

      Hashtbl.remove funcs name;
      (* The wire name might be different from the name *)
      let wire_name = get_wire_name !description name in
      Hashtbl.add funcs wire_name (Some rpcfn)

end
