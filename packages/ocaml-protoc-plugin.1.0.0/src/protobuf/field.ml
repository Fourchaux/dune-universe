type t =
  | Varint of Int64.t (* int32, int64, uint32, uint64, sint32, sint64, bool, enum *)
  | Fixed_64_bit of Int64.t (* fixed64, sfixed64, double *)
  | Length_delimited of {
      offset : int;
      length : int;
      data : string;
    } (* string, bytes, embedded messages, packed repeated fields *)
  | Fixed_32_bit of Int32.t (* fixed32, sfixed32, float *)
let show = function
  | Varint i -> Printf.sprintf "Varint %Ld" i
  | Fixed_64_bit i -> Printf.sprintf "Fixed_64_bit %Ld" i
  | Length_delimited { offset; length; data = _} ->  Printf.sprintf "Length_delimited: %d" (length - offset)
  | Fixed_32_bit i -> Printf.sprintf "Fixed_32_bit %ld" i

let varint v = Varint v
let fixed_32_bit v = Fixed_32_bit v
let fixed_64_bit v = Fixed_64_bit v
let length_delimited ?(offset=0) ?length data =
  let length = Option.value ~default:(String.length data - offset) length in
  Length_delimited {offset; length; data}
