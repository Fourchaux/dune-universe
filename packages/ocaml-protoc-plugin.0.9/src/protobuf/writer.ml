(** Some buffer to hold data, and to read and write data *)

open Base
open Spec

let sprintf = Printf.sprintf
let printf = Stdlib.Printf.printf

type t = {mutable fields : Spec.field list}

type error =
  [ `Premature_end_of_input
  | `Unknown_field_type of int ]
[@@deriving show]

let init () = {fields = []}

let rec size_of_field = function
  | Varint 0 -> 1
  | Varint n when n > 0 ->
    let bits = Float.(iround_down_exn (log (of_int n) /. log 2.0)) + 1 in
    ((bits - 1) / 7) + 1
  | Varint _ -> (* Negative *) 10
  | Fixed_32_bit _ -> 4
  | Fixed_64_bit _ -> 8
  | Length_delimited {length; _} -> size_of_field (Varint length) + length

let size t =
  List.fold_left ~init:0 ~f:(fun acc field -> acc + size_of_field field) t.fields

let write_varint buffer ~offset v =
  let rec inner ~offset v : int =
    let open Int64 in
    match v land 0x7FL, v lsr 7 with
    | v, 0L ->
      Bytes.set buffer offset (v |> to_int_exn |> Char.of_int_exn);
      Int.(offset + 1)
    | v, rem ->
      Bytes.set buffer offset (v lor 0x80L |> to_int_exn |> Char.of_int_exn);
      inner ~offset:Int.(offset + 1) rem
  in
  inner ~offset (Int64.of_int v)

let write_fixed32 buffer ~offset v =
  EndianBytes.LittleEndian.set_int32 buffer offset v;
  offset + 4

let write_fixed64 buffer ~offset v =
  EndianBytes.LittleEndian.set_int64 buffer offset v;
  offset + 8

let write_length_delimited buffer ~offset ~src ~src_pos ~len =
  let offset = write_varint buffer ~offset len in
  (* Copy string to bytes, should exist *)
  Bytes.blit ~src:(Bytes.of_string src) ~src_pos ~dst:buffer ~dst_pos:offset ~len;
  offset + len

let write_field buffer ~offset = function
  | Varint v -> write_varint buffer ~offset v
  | Fixed_32_bit v -> write_fixed32 buffer ~offset v
  | Fixed_64_bit v -> write_fixed64 buffer ~offset v
  | Length_delimited {offset = src_pos; length; data} ->
    write_length_delimited buffer ~offset ~src:data ~src_pos ~len:length

let contents t =
  let size = size t in
  let t = List.rev t.fields in
  let buffer = Bytes.create size in
  let next_offset =
    List.fold_left ~init:0 ~f:(fun offset field -> write_field buffer ~offset field) t
  in
  assert (next_offset = size);
  Bytes.to_string buffer

let add_field t field = t.fields <- field :: t.fields

(** Add the contents of src as is *)
let concat t ~src =
  t.fields <- src.fields @ (t.fields)

let write_field_header : t -> int -> int -> unit =
 fun t index field_type ->
  let header = (index lsl 3) + field_type in
  add_field t (Varint header)

let write_field : t -> int -> field -> unit =
 fun t index field ->
  let field_type =
    match field with
    | Varint _ -> 0
    | Fixed_64_bit _ -> 1
    | Length_delimited _ -> 2
    | Fixed_32_bit _ -> 5
  in
  write_field_header t index field_type;
  add_field t field

(** Add the contents of src as a length_delimited field *)
let concat_as_length_delimited t ~src index =
  let size = size src in
  write_field_header t index 2;
  add_field t (Varint size);
  t.fields <- src.fields @ t.fields

let dump t =
  contents t
  |> String.to_list
  |> List.map ~f:Char.to_int
  |> List.map ~f:(sprintf "%02x")
  |> String.concat ~sep:"-"
  |> printf "Buffer: %s\n"

let%test _ =
  let buffer = init () in
  write_field buffer 1 (Varint 1);
  let c = contents buffer in
  String.length c = 2 && String.equal c "\x08\x01"
