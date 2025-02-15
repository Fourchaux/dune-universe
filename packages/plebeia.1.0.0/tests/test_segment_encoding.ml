open Plebeia.Internal
open Test_utils

let bit_slow_encode_segment seg =
  let open Segment in
  let seg = to_sides seg in
  let len = List.length seg in
  if len > Segment.max_length then failwith "segment is too long";
  let head_zero_bits = Segment.max_length - len in
  let head_zero_bytes = head_zero_bits / 8 in
  let bytes = Bytes.make 28 '\000' in
  let byte_pos = head_zero_bytes in
  let bit_pos = head_zero_bits mod 8 in
  let rec make_byte bit_pos st seg = 
    match seg with
    | _ when bit_pos = 8 -> (Char.chr st, seg)
    | [] -> assert false
    | x :: seg -> make_byte (bit_pos+1) ((st lsl 1) lor (if x = Left then 0 else 1)) seg
  in
  let rec fill_bytes byte_pos bit_pos = function
    | [] -> 
        assert (byte_pos = 28 && bit_pos = 0);
        Bytes.to_string bytes
    | seg ->
        let (c, seg) = make_byte bit_pos 0 seg in
        Bytes.unsafe_set bytes byte_pos c;
        let byte_pos' = byte_pos + 1 in
        if byte_pos' > 28 then assert false; (* segment is too long *)
        fill_bytes byte_pos' 0 seg
  in
  fill_bytes byte_pos bit_pos (Right :: seg @ [Left ; Right] : side list) (* XXX inefficient *)

let slow_encode_segment seg =
  let open Segment in
  let seg = to_sides seg in
  let len = List.length seg in
  if len > Segment.max_length then failwith "segment is too long";
  let head_zero_bits = Segment.max_length - len in
  let rec make = function
    | 0 -> Right :: seg @ [ Left ; Right ] (* inefficient, but it is for test. *)
    | n -> Left :: make (n-1)
  in
  let rec chars_of_seg = function
    | [] -> []
    | x1 :: x2 :: x3 :: x4 :: x5 :: x6 :: x7 :: x8 :: seg ->
        let bit = function
          | Left -> 0
          | Right -> 1
        in
        let byte = 
          (bit x1) * 128
          + (bit x2) * 64
          + (bit x3) * 32
          + (bit x4) * 16
          + (bit x5) * 8
          + (bit x6) * 4
          + (bit x7) * 2
          + (bit x8) * 1
        in
        Char.chr byte :: chars_of_seg seg
    | _ -> assert false
  in
  let b = Buffer.create 28 in
  List.iter (Buffer.add_char b) @@ chars_of_seg @@ make head_zero_bits;
  Buffer.contents b

let encoding_test seg =
  let h = Segment.encode seg in
  let h' = slow_encode_segment seg in
  let h'' = bit_slow_encode_segment seg in
  assert (h = h');
  assert (h = h'');
  assert (Segment.(equal (decode h) seg))

let test_correctness st =
  for _ = 1 to 1000000 do
    let seg = random_short_segment st in
    encoding_test seg
  done;
  for _ = 1 to 1000000 do
    let seg = random_segment st in
    let h = Segment.encode seg in
    assert (Segment.(equal (decode h) seg))
  done

let test_perf st =
  prerr_endline "Making 1000000 random segments...";
  let segs = List.init 1000000 (fun _ -> random_short_segment st) in
  prerr_endline "done.";
  let (_, _t3) = timed (fun () -> List.iter (fun s -> ignore @@ bit_slow_encode_segment s) segs) in
  let (_, _t1) = timed (fun () -> List.iter (fun s -> ignore @@ Segment.encode s) segs) in
  let (_, _t2) = timed (fun () -> List.iter (fun s -> ignore @@ slow_encode_segment s) segs) in
  let (_, t3) = timed (fun () -> List.iter (fun s -> ignore @@ bit_slow_encode_segment s) segs) in
  let (_, t1) = timed (fun () -> List.iter (fun s -> ignore @@ Segment.encode s) segs) in
  let (_, t2) = timed (fun () -> List.iter (fun s -> ignore @@ slow_encode_segment s) segs) in
  Format.eprintf "encode_segment           of 1000000: %f secs@." t1;
  Format.eprintf "slow_encode_segment      of 1000000: %f secs@." t2;
  Format.eprintf "bit_slow_encode_segment  of 1000000: %f secs@." t3

let test st =
  test_correctness st;
  test_perf st

let () = test (Random.State.make_self_init ())
