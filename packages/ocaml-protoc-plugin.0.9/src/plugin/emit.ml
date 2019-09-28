open Base

let sprintf = Printf.sprintf
let annot = ref ""
let debug = ref false
let opens = ref []

let parse_parameters parameters =
  String.split ~on:';' parameters
  |> List.iter ~f:(fun param ->
      match String.split ~on:'=' param with
      | "annot" :: values -> annot := String.concat ~sep:"=" values
      | "open" :: values -> opens := String.concat ~sep:"=" values :: !opens
      | ["debug"] -> debug := true
      | _ -> failwith ("Unknown parameter: " ^ param)
    )

(** Taken from: https://caml.inria.fr/pub/docs/manual-ocaml/lex.html *)
let is_reserved = function
  | "and" | "as" | "assert" | "asr" | "begin" | "class" | "constraint" | "do" | "done"
  | "downto" | "else" | "end" | "exception" | "external" | "false" | "for" | "fun"
  | "function" | "functor" | "if" | "in" | "include" | "inherit" | "initializer"
  | "land" | "lazy" | "let" | "lor" | "lsl" | "lsr" | "lxor" | "match" | "method"
  | "mod" | "module" | "mutable" | "new" | "nonrec" | "object" | "of" | "open" | "or"
  | "private" | "rec" | "sig" | "struct" | "then" | "to" | "true" | "try" | "type"
  | "val" | "virtual" | "when" | "while" | "with" ->
    true
  | "from_proto" | "to_proto" -> true
  | _ -> false

(* Remember to mangle reserved keywords *)
let module_name name = String.capitalize (Option.value_exn name)

(* Remember to mangle reserved keywords *)
let field_name (field_name : string option) =
  match String.uncapitalize (Option.value_exn field_name) with
  | name when is_reserved name -> name ^ "'"
  | name -> name

let variant_name name = module_name name

let constructor_name Spec.Descriptor.{name; number = _; options = _} =
  String.capitalize (Option.value_exn name)

let to_string_opt = function
  | Some s -> s
  | None -> "<None>"

(** Slightly overloaded name here.
    Its also used for all other types which would go into a module *)
type message = {
  module_name : string;
  signature : Code.t;
  implementation : Code.t;
}

let log fmt =
  match !debug with
  | true -> Stdlib.(Printf.eprintf (fmt ^^ "\n%!"))
  | false -> Stdlib.Printf.ifprintf Stdlib.stderr fmt

let emit_enum_type
    Spec.Descriptor.{name; value; options = _; reserved_range = _; reserved_name = _}
    : message
  =
  let module_name = module_name name in
  let signature = Code.init () in
  let implementation = Code.init () in
  let t = Code.init () in
  Code.emit t `None "type t = %s %s" (List.map ~f:constructor_name value |> String.concat ~sep:" | ") !annot;
  Code.append signature t;
  Code.append implementation t;
  Code.emit signature `None "val to_int: t -> int";
  Code.emit signature `None "val from_int: int -> t Protobuf.Deserialize.result";
  Code.emit implementation `Begin "let to_int = function";
  List.iter ~f:(fun v ->
      Code.emit implementation `None "| %s -> %d" (constructor_name v) (Option.value_exn v.number)
    ) value;
  Code.emit implementation `End "";
  Code.emit implementation `Begin "let from_int = function";
  List.iter ~f:(fun v ->
      Code.emit implementation `None "| %d -> Ok %s" (Option.value_exn v.number) (constructor_name v)
    ) value;
  Code.emit implementation `None "| n -> Error (`Unknown_enum_value n)";
  Code.emit implementation `End "";
  {module_name; signature; implementation}

let is_message_type = function
  | Spec.Descriptor.{type_ = Some Type_message; _ } -> true
  | _ -> false

let protobuf_type_of_field ~prefix scope field_descriptor =
  let open Spec.Descriptor in
  let type_spec type_name = function
    | Type_double -> "Double"
    | Type_float -> "Float"
    | Type_int64 -> "Int64"
    | Type_uint64 -> "UInt64"
    | Type_int32 -> "Int32"
    | Type_fixed64 -> "Fixed64"
    | Type_fixed32 -> "Fixed32"
    | Type_sfixed32 -> "SFixed32"
    | Type_sfixed64 -> "SFixed64"
    | Type_sint32 -> "SInt32"
    | Type_sint64 -> "SInt64"
    | Type_uint32 -> "UInt32"
    | Type_bool -> "Bool"
    | Type_string -> "String"
    | Type_bytes -> "Bytes"
    | Type_enum ->
      let to_int_func =
        Scope.get_scoped_name ~postfix:(prefix ^ "_int") scope type_name
      in
      sprintf "Enum %s" to_int_func
    | Type_message -> failwith "Message types are not basic"
    | _ -> failwith "Unknown type";
  in
  match field_descriptor with
  | {label = Some Label_repeated; type_ = Some Type_message; type_name; _} ->
    let proto_func = Scope.get_scoped_name ~postfix:(prefix ^ "_proto") scope type_name in
    sprintf "RepeatedMessage %s" proto_func
  | {label = Some Label_repeated; type_ = Some type_; type_name; _} -> sprintf "Repeated (%s)" (type_spec type_name type_)
  | { type_ = None; _ } -> failwith "Abstract types not supported"
  | {label = _; type_ = Some Type_message; type_name; _} ->
    let proto_func = Scope.get_scoped_name ~postfix:(prefix ^ "_proto") scope type_name in
    sprintf "Message %s" proto_func
  | {label = _; type_ = Some type_; type_name; _} ->
    sprintf "Basic (%s)" (type_spec type_name type_)



(** Get the stringified name of a type.
    Consider moving this to Protocol somewhere. So types are next to each other.
    Currently this needs to be in sync with the Protobuf.Serialize.protobuf_type
*)
let type_of_field scope field_descriptor =
  let open Spec.Descriptor in
  let base_type =
    match field_descriptor with
    | {type_ = Some Type_double; _} | {type_ = Some Type_float; _} -> "float"
    | {type_ = Some Type_int64; _}
    | {type_ = Some Type_uint64; _}
    | {type_ = Some Type_int32; _}
    | {type_ = Some Type_fixed64; _}
    | {type_ = Some Type_fixed32; _}
    | {type_ = Some Type_sfixed32; _}
    | {type_ = Some Type_sfixed64; _}
    | {type_ = Some Type_sint32; _}
    | {type_ = Some Type_sint64; _}
    | {type_ = Some Type_uint32; _} -> "int"
    | {type_ = Some Type_bool; _} -> "bool"
    | {type_ = Some Type_string; _} -> "string"
    | {type_ = Some Type_group; _} -> failwith "Groups are deprecated"
    | {type_ = Some Type_message; type_name; oneof_index = Some _; _} ->
      Scope.get_scoped_name scope ~postfix:"t" type_name
    | {type_ = Some Type_message; type_name; oneof_index = None; _} ->
      Scope.get_scoped_name ~postfix:"t" scope type_name
    | {type_ = Some Type_bytes; _} -> "bytes"
    | {type_ = Some Type_enum; type_name; _} ->
      Scope.get_scoped_name ~postfix:"t" scope type_name
    | {type_ = None; _} -> failwith "Abstract types cannot be"
  in
  match field_descriptor with
  | {label = Some Label_repeated; _} -> base_type ^ " list"
  | {oneof_index = None; type_ = Some Type_message; _} -> base_type ^ " option"
  | _ -> base_type

let emit_field t scope (field : Spec.Descriptor.field_descriptor_proto) =
  Code.emit t `None "%s: %s;" (field_name field.name) (type_of_field scope field)

let emit_oneof_fields t scope
    ((oneof_decl : Spec.Descriptor.oneof_descriptor_proto), fields)
  =
  (* Emit a polymorphic variant type. *)
  let variants = List.map ~f:(fun field ->
      let type_ = type_of_field scope field in
      let name = variant_name field.name in
      sprintf "`%s of %s" name type_
    ) fields
  in
  Code.emit t `None "%s: [ %s ];" (field_name oneof_decl.name) (String.concat ~sep:" | " variants)

(** Return a list of plain fields + a list of fields per oneof_decl *)
let split_oneof_decl fields oneof_decls =
  List.foldi ~init:(fields, []) ~f:(fun i (fields, oneof_decls) oneof_decl ->
      let oneof_fields, rest = List.partition_tf ~f:(function
          | {Spec.Descriptor.oneof_index = Some i'; _} -> i = i'
          | {Spec.Descriptor.oneof_index = None; _} -> false
        ) fields
      in
      rest, (oneof_decl, oneof_fields) :: oneof_decls
    ) oneof_decls

let inject (signature', implementation') signature implementation =
  Code.append signature signature';
  Code.append implementation implementation'

let emit_service_type scope Spec.Descriptor.{ name; method_ = methods; _ } =
  let emit_method t Spec.Descriptor.{ name; input_type; output_type; _} =
    Code.emit t `Begin "let %s = " (field_name name);
    Code.emit t `None "( (module %s : Protobuf.Service.Message with type t = %s ), "
      (Scope.get_scoped_name scope input_type)
      (Scope.get_scoped_name ~postfix:"t" scope input_type);
    Code.emit t `None "  (module %s : Protobuf.Service.Message with type t = %s ) ) "
      (Scope.get_scoped_name scope output_type)
      (Scope.get_scoped_name ~postfix:"t" scope output_type)
  in
  let t = Code.init () in
  Code.emit t `Begin "module %s = struct" (module_name name);
  List.iter ~f:(emit_method t) methods;
  Code.emit t `End "end";
  t

let emit_deserialization_function ~is_map_entry scope all_fields (oneof_decls: Spec.Descriptor.oneof_descriptor_proto list) =
  let fields, oneof_decls = split_oneof_decl all_fields oneof_decls in
  let signature = Code.init () in
  let implementation = Code.init () in
  Code.emit signature `None "val from_proto: Protobuf.Reader.t -> (t, Protobuf.Deserialize.error) result";
  let _field_names = List.map ~f:(fun field -> field_name field.name) fields in
  Code.emit implementation `Begin "let rec from_proto data =";
  Code.emit implementation `None "let open Base.Result.Monad_infix in";
  List.iter ~f:(fun field ->
      let index = Option.value_exn field.number in
      let typ = protobuf_type_of_field ~prefix:"from" scope field in
      Code.emit implementation `None "let (sentinal_%d, deser_%d) = Protobuf.Deserialize.sentinal (%s) in"
        index index typ
    ) fields;
  let spec = List.map ~f:(fun field ->
      sprintf "(%d, deser_%d)" (Option.value_exn field.number) (Option.value_exn field.number)
    ) fields
  in
  List.iteri ~f:(fun idx (_decl, fields) ->
      let spec = List.map ~f:(fun field ->
          let constr = match is_message_type field with
            | true -> sprintf "function Some v -> `%s v | None -> failwith \"oneof fields cannot be null.\"" (variant_name field.name)
            | false -> sprintf "fun v -> `%s v" (variant_name field.name)
          in
          let index = Option.value_exn field.number in
          let spec = protobuf_type_of_field ~prefix:"from" scope field in
          sprintf "Oneof (%d, %s, %s)" index spec constr;
        ) fields
      in
      Code.emit implementation `None "let (oneof_sentinal_%d, oneof_spec_%d) = Protobuf.Deserialize.oneof_sentinal [ %s ] in"
        idx idx (String.concat ~sep:"; " spec)
    ) oneof_decls;
  let oneof_specs = List.mapi ~f:(fun idx _ -> sprintf "oneof_spec_%d" idx) oneof_decls in
  Code.emit implementation `None "let spec = %s @ [ %s ] in" (String.concat ~sep:" @ " ("[]" :: oneof_specs)) (String.concat ~sep:"; " spec);
  Code.emit implementation `None "Protobuf.Deserialize.deserialize spec data >>= fun () -> ";
  List.iteri ~f:(fun idx _ ->
      Code.emit implementation `None "oneof_sentinal_%d () >>= fun oneof_%d -> " idx idx
    ) oneof_decls;

  (* Construct the record *)
  let fields = List.map ~f:(fun field ->
      let name = field_name field.name in
      let index = Option.value_exn field.number in
      sprintf "%s = sentinal_%d ()" name index
    ) fields
  in
  let oneof_fields = List.mapi ~f:(fun idx (decl, _) -> sprintf "%s = oneof_%d" (field_name decl.name) idx) oneof_decls in
  let construct = match all_fields with
    | [] -> "()"
    | [_; _] when is_map_entry ->
      "( sentinal_1 (), sentinal_2 () )"
    | _  ->
      sprintf "{ %s }" (String.concat ~sep:"; " (fields @ oneof_fields))
  in
  Code.emit implementation `None "Base.Result.return %s" construct;
  Code.emit implementation `End "[@@warning \"-39\"]";
  signature, implementation

(* Return code for signature and implementation *)
let emit_serialization_function ~is_map_entry scope all_fields (oneof_decls: Spec.Descriptor.oneof_descriptor_proto list) =
  let fields, oneof_decls = split_oneof_decl all_fields oneof_decls in
  let signature = Code.init () in
  let implementation = Code.init () in
  Code.emit signature `None "val to_proto: t -> Protobuf.Writer.t";
  let oneof_field_spec =
    oneof_decls
    |> List.map ~f:(fun (_decl, fields) ->
        let cases =
          List.map ~f:(fun (field : Spec.Descriptor.field_descriptor_proto) ->
              let wrap_some = match is_message_type field with
                | true -> "Some"
                | false -> ""
              in
              sprintf "`%s v -> Protobuf.Serialize.(serialize ((%d, %s) ^:: Nil) (%s v))" (variant_name field.name) (Option.value_exn field.number) (protobuf_type_of_field ~prefix:"to" scope field) wrap_some
            ) fields
        in
        sprintf "(0, Oneof (function %s)) ^:: " (String.concat ~sep:"| " cases)
      )
    |> String.concat
  in
  let protocol_field_spec =
    fields
    |> List.map ~f:(fun (field : Spec.Descriptor.field_descriptor_proto) ->
        field.number, protobuf_type_of_field ~prefix:"to" scope field)
    |> List.map ~f:(fun (index, tpe) -> sprintf "(%d, %s) ^:: " (Option.value_exn index) tpe)
    |> String.concat
  in
  (* Destruct the type. *)
  let field_names = List.map ~f:(fun field -> field_name field.name) fields in
  let oneof_names = List.map ~f:(fun (decl, _) -> field_name decl.name) oneof_decls in
  let destruct =
    match all_fields with
    | [] -> "()"
    | [key; value] when is_map_entry ->
      sprintf "( %s, %s )" (field_name key.name) (field_name value.name)
    | _ -> String.concat ~sep:"; " (field_names @ oneof_names) |> sprintf "{ %s }"
  in
  Code.emit implementation `Begin "let rec to_proto %s = " destruct;
  Code.emit implementation `None "let open Protobuf.Serialize in";
  Code.emit implementation `None "serialize (%s %sNil) %s %s"
    protocol_field_spec oneof_field_spec (String.concat ~sep:" " field_names) (String.concat ~sep:" " oneof_names);
  Code.emit implementation `End "[@@warning \"-39\"]";
  signature, implementation

let emit_message_type ~is_map_entry scope all_fields oneof_decls =
  let fields, oneof_decls = split_oneof_decl all_fields oneof_decls in
  let t = Code.init () in
  let () =
    match all_fields with
    | [] -> Code.emit t `None "type t = unit %s" !annot
    | [key; value] when is_map_entry ->
      (* Generate tuple instead of record *)
      Code.emit t `None "type t = ( %s * %s ) %s"
        (type_of_field scope key) (type_of_field scope value) !annot
    | _ ->
      Code.emit t `Begin "type t = {";
      List.iter ~f:(emit_field t scope) fields;
      List.iter ~f:(emit_oneof_fields t scope) oneof_decls;
      Code.emit t `End "} %s" !annot
  in
  t

let is_map_entry options =
  match options with
  | Some Spec.Descriptor.{ map_entry = Some true; _ } -> true
  | _ -> false

let rec emit_message scope
    Spec.Descriptor.
      {
        name;
        field = fields;
        extension = _;
        nested_type = nested_types;
        enum_type = enum_types;
        extension_range = _;
        oneof_decl = oneof_decls;
        options;
        reserved_range = _;
        reserved_name = _;
      }
  : message =
  let rec emit_nested_types ~signature ~implementation ?(is_first = true) nested_types =
    let emit_sub dest ~is_implementation ~is_first {module_name; signature; implementation} =
      let () =
        match is_first with
        | true -> Code.emit dest `Begin "module rec %s : sig" module_name
        | false -> Code.emit dest `Begin "and %s : sig" module_name
      in
      Code.append dest signature;
      let () =
        match is_implementation with
        | false -> ()
        | true ->
          Code.emit dest `EndBegin "end = struct ";
          Code.append dest implementation
      in
      Code.emit dest `End "end";
      ()
    in
    match nested_types with
    | [] -> ()
    | sub :: subs ->
      emit_sub ~is_implementation:false signature ~is_first sub;
      emit_sub ~is_implementation:true implementation ~is_first sub;
      emit_nested_types ~signature ~implementation ~is_first:false subs
  in
  let signature = Code.init () in
  let implementation = Code.init () in
  (* Ignore empty modules *)
  let module_name, scope =
    match name with
    | None -> "", scope
    | Some _ ->
      let module_name = module_name name in
      module_name, Scope.push scope module_name
  in
  List.map ~f:emit_enum_type enum_types @ List.map ~f:(emit_message scope) nested_types
  |> emit_nested_types ~signature ~implementation;
  let () =
    match name with
    | Some _name ->
      Code.emit signature `None "val name: unit -> string";
      Code.emit implementation `None "let name () = \"%s\"" (Scope.get_current_scope scope);
      let is_map_entry = is_map_entry options in
      let t = emit_message_type ~is_map_entry scope fields oneof_decls in
      Code.append signature t;
      Code.append implementation t;
      inject
        (emit_serialization_function ~is_map_entry scope fields oneof_decls)
        signature
        implementation;
      inject
        (emit_deserialization_function ~is_map_entry scope fields oneof_decls)
        signature
        implementation
    | None -> ()
  in
  {module_name; signature; implementation}

let rec wrap_packages scope message_type services = function
  | [] ->
    let {module_name = _; implementation; _} = emit_message scope message_type in
    List.iter ~f:(fun service ->
        Code.append implementation (emit_service_type scope service)
      ) services;
    implementation

  | package :: packages ->
    let implementation = Code.init () in
    let package_name = module_name (Some package) in
    let scope = Scope.push scope package in
    Code.emit implementation `Begin "module %s = struct" package_name;
    Code.append implementation (wrap_packages scope message_type services packages);
    Code.emit implementation `End "end";
    implementation

let parse_proto_file
      scope
      Spec.Descriptor.{ name; package; dependency = _; public_dependency = _;
                        weak_dependency = _; message_type = message_types;
                        enum_type = enum_types; service = services; extension = _;
                        options = _; source_code_info = _; syntax; }
  =
  log "parse_proto_file: Name = %s. Package=%s, syntax=%s. enums: %d"
    (to_string_opt name)
    (to_string_opt package)
    (to_string_opt syntax)
    (List.length enum_types);
  let message_type =
    Spec.Descriptor.default_descriptor_proto ~name:None ~nested_type:message_types ~enum_type:enum_types ()
  in
  (* No real reason to emit a .mli *)
  let implementation =
    wrap_packages scope message_type services (Option.value_map ~default:[] ~f:(String.split ~on:'.') package)
  in
  let out_name =
    Option.map ~f:(fun proto_file_name ->
        let name = match String.chop_suffix ~suffix:".proto" proto_file_name with
          | None -> proto_file_name
          | Some stem -> stem
        in
        Printf.sprintf "%s.ml" name
      ) name
  in
  out_name, implementation

let parse_request Spec.Plugin.{file_to_generate = files_to_generate; parameter = parameters; proto_file = proto_files; compiler_version = _} =
  Option.iter ~f:parse_parameters parameters;
  log "*** Request to parse proto_files: %s. Parameter: %s" (String.concat ~sep:"; " files_to_generate) (Option.value ~default:"<None>" parameters);
  (* Find the correct file to process *)
  let target_proto_files = List.filter ~f:(fun Spec.Descriptor.{name; _} ->
      List.mem ~equal:String.equal files_to_generate (Option.value_exn name)
    ) proto_files
  in
  let scope = Scope.init proto_files in
  let result =
    List.map ~f:(fun proto_file ->
      let scope = Scope.push scope (Option.value_exn proto_file.name |> Scope.module_name_of_proto) in
      parse_proto_file scope proto_file
    ) target_proto_files
    |> List.map ~f:(fun (v, code) ->
      log "Processed %s" (Option.value v ~default:"<None>");
      let c = Code.init () in
      List.iter ~f:(Code.emit c `None "open %s") (List.rev !opens);
      Code.append c code;
      (v, c)
    )
  in
  (match !debug with
   | true -> List.iter ~f:(fun (_, code) -> log "%s" (Code.contents code)) result
   | false -> ());
  result
