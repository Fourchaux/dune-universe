(** Misc *)

open ExtLib
open Printf

open Prelude

let period n f =
  let count = ref 0 in
  (fun () -> incr count; if !count mod n = 0 then f !count)

let timely period ?first f =
  assert (period > 0.);
  let next = ref (match first with Some first -> first | None -> Time.get () +. period) in
  (fun x -> if Time.get () > !next then begin Std.finally (fun () -> next := Time.get () +. period) f x end)

let timely_counter period f =
  let cnt = ref 0 in
  let logger = timely period (fun () -> f !cnt) in
  fun () -> begin
    incr cnt;
    logger ();
  end

type ewma = (float -> unit) * (unit -> float)

let ewma alpha : ewma =
  let x = ref nan in
  (fun f -> if compare nan !x = 0 then x := f else x := !x +. alpha *. (f -. !x)),
  (fun () -> if compare nan !x = 0 then 0. else !x)

let uniq p e =
  let h = Hashtbl.create 16 in
  Enum.filter (fun x ->
    let k = p x in
    if Hashtbl.mem h k then false else (Hashtbl.add h k (); true)) e

let all_uniq p e =
  let h = Hashtbl.create 16 in
  let rec loop () =
    match Enum.get e with
    | None -> true
    | Some x ->
      let k = p x in
      if Hashtbl.mem h k then false else (Hashtbl.add h k (); loop ())
  in
  loop ()

let list_uniq p = List.of_enum $ uniq p $ List.enum

let list_sorted_uniq p =
  List.rev $ List.fold_left begin fun acc x ->
    match acc with
    | y :: _ when p x y -> acc
    | _ -> x :: acc
  end []

let random_int state =
  match state with
  | None -> Random.int
  | Some t -> Random.State.int t

let list_random_exn ?state l = List.nth l (random_int state (List.length l))

let list_random ?state = function
  | [] -> None
  | l -> Some (list_random_exn ?state l)

let array_random_exn ?state a = a.(random_int state (Array.length a))
let array_random ?state = function [||] -> None | a -> Some (array_random_exn ?state a)

let array_rfindi p a =
  let j = ref 0 in
  try
    for i = Array.length a - 1 downto 0 do
      if p (Array.unsafe_get a i) then begin j := i; raise Exit end
    done;
    raise Not_found
  with Exit -> !j

let array_rfind p a = a.(array_rfindi p a)

let array_iter_rev f a = for i = Array.length a - 1 downto 0 do f (Array.unsafe_get a i) done

let shuffle ?state a =
   let random = random_int state in
   for i = pred (Array.length a) downto 1 do
     let j = random (succ i) in
     if i <> j (* faster to omit this test with arrays of about 100000 elements or more *) then (
       let tmp = Array.unsafe_get a i in
       Array.unsafe_set a i (Array.unsafe_get a j);
       Array.unsafe_set a j tmp
     )
   done

let partition n l =
  assert (n >= 0);
  if n < 2 then [| l |] else
  let a = Array.make n [] in
  ExtList.List.iteri (fun i x -> let i = i mod n in a.(i) <- x :: a.(i)) l;
  a

let unpartition a =
  match a with
  | [| l |] -> l
  | _ ->
  let a = Array.map List.rev a in
  let l = ref [] in
  let more = ref true in
  while !more do
    more := false;
    for i = 0 to Array.length a - 1 do
      match a.(i) with
      | [] -> ()
      | x::xs -> more := true; a.(i) <- xs; l := x :: !l
    done;
  done;
  assert (Array.for_all ((=)[]) a);
  List.rev !l

let stable_partition n l =
  assert (n >= 0);
  if n <= 1 then [l] else
  let c = List.length l / n in
  let rec loop acc uneven rest idx =
    if idx <= 1 then rest::acc else
    let d = (uneven + n - 1) / n in
    let xs, ys = List.split_nth (c + d) rest in
    loop (xs::acc) (uneven - d) ys (idx - 1)
  in
  List.rev @@ loop [] (List.length l mod n) l n

let stable_unpartition = List.flatten

let slice b e = List.take (e - b + 1) $ List.drop b

let file_lines_exn file =
  Control.with_open_in_txt file begin fun ch ->
    Std.input_lines ch |> List.of_enum
  end

let make_config_lines =
  List.filter_map begin fun s ->
    let (s, _comment) = Stre.dividec s '#' in
    let s = String.strip s in
    if s <> "" then Some s else None
  end

let config_lines_exn = make_config_lines $ file_lines_exn

let file_lines_exn file = try file_lines_exn file with exn -> Exn.fail ~exn "file_lines %s" file
let config_lines_exn file = try config_lines_exn file with exn -> Exn.fail ~exn "config_lines %s" file

let file_lines file = try file_lines_exn file with _ -> []
let config_lines file = try config_lines_exn file with _ -> []

let hashtbl_find h f k =
  try Hashtbl.find h k with Not_found -> let v = f () in Hashtbl.replace h k v; v

let binary_search' arr cmp x =
  let rec loop a b =
    match b - a with
    | 0 -> None
    | 1 -> if cmp arr.(a) x = 0 then Some arr.(a) else None
    | n ->
      let mid = a + n / 2 in
      let v = arr.(mid) in
      match cmp v x with
      | 0 -> Some v
      | n when n > 0 -> loop a mid
      | _ (* n when n < 0 *) -> loop (mid+1) b
  in
  loop 0 (Array.length arr)

let binary_search a b c = Option.is_some @@ binary_search' a b c

let chunk n l =
  assert (n > 0);
  let chunks = ref [] in
  let get_chunk e =
    let rec loop acc = function
      | 0 -> acc
      | n -> match Enum.get e with None -> acc | Some x -> loop (x::acc) (n-1)
    in
    chunks := loop [] n :: !chunks
  in
  let rec loop e =
    match Enum.peek e with
    | None -> List.rev !chunks
    | _ -> get_chunk e; loop e
  in
  loop (List.enum l)

let chunk_e n e =
  assert (n > 0);
  let fin () = raise Enum.No_more_elements in
  Enum.from (fun () ->
    let i = ref n in
    if Enum.is_empty e then fin () else
    Enum.from (fun () -> match !i with
      | 0 -> fin ()
      | _ -> decr i; match Enum.get e with None -> fin () | Some x -> x))

let chunk_a n a =
  assert (n > 0);
  let chunks = Array.length a / n in
  let last_n = Array.length a mod n in
  let last = if last_n = 0 then 0 else 1 in
  List.init (chunks + last) (fun i -> Array.sub a (i*n) (if i = chunks then last_n else n))

let bytes_string_f =
  let kbyte = 1024. in
  let mbyte = kbyte *. 1024. in
  let gbyte = mbyte *. 1024. in
  let tbyte = gbyte *. 1024. in
  let pbyte = tbyte *. 1024. in
  let ebyte = pbyte *. 1024. in
  fun f ->
  let a = abs_float f in
  if a < kbyte then sprintf "%dB" (int_of_float f) else
  if a < mbyte then sprintf "%dKB" (int_of_float (f /. kbyte)) else
  if a < gbyte then sprintf "%.1fMB" (f /. mbyte) else
  if a < tbyte then sprintf "%.1fGB" (f /. gbyte) else
  if a < pbyte then sprintf "%.1fTB" (f /. tbyte) else
  if a < ebyte then sprintf "%.1fPB" (f /. pbyte) else
  sprintf "%.1fEB" (f /. ebyte)

let bytes_string = bytes_string_f $ float_of_int
let bytes_string_i64 = bytes_string_f $ Int64.to_float

let bytes_of_words x = Sys.word_size / 8 * x
let bytes_of_words_f x = float (Sys.word_size / 8) *. x

let caml_words = bytes_string $ bytes_of_words
let caml_words_f = bytes_string_f $ bytes_of_words_f

(* EMXIF *)

class timer_start start =
  object
    val mutable start = start
    val mutable l = []
    method reset = start <- Time.now (); l <- []
    method record name t = l <- (name, t) :: l
    method mark name = l <- (name, Time.now ()) :: l
    method show = List.rev l |> List.map (fun (name, t) -> sprintf "%s:%s" name (Time.compact_duration @@ t -. start)) |> String.concat " "
    method json : (string * Yojson.Safe.t) list = List.rev l |> List.map (fun (name, t) -> name, (`Int (Time.to_ms (t -. start))))
    method get = Time.ago start
    method get_str = Time.ago_str start
    method get_state = (start, l)
end

class timer = object inherit timer_start (Time.now ()) end

let uptime = new timer

let speed n t = float n /. (max t epsilon_float)

let perform ?name f x =
  let t = new timer in
  try
    Option.may (Log.self #info "Action %S started") name;
    let () = f x in
    Option.may (fun name -> Log.self #info "Action %S finished (elapsed %s)" name t#get_str) name;
    true
  with
    exn ->
      let name = Option.map_default (Printf.sprintf " %S") "" name in
      Log.self #error ~exn ~backtrace:true "Action%s aborted with uncaught exception (elapsed %s)" name t#get_str;
      false

let log ?name f x = let (_:bool) = perform ?name f x in ()
let log_do ?name f = log ?name f ()

let io_copy input output =
  try
    let size = 16 * 1024 in
    let s = String.create size in
    while true do
      let n = IO.input input s 0 size in
      if n = 0 then raise IO.No_more_input;
      let (_:int) = IO.really_output output s 0 n in
      ()
    done
  with IO.No_more_input -> ()

let io_null = IO.create_out ~write:(fun _ -> ()) ~output:(fun _ _ len -> len) ~flush:id ~close:id

let compare_by f a b = Stdlib.compare (f a) (f b)
let compare2 f g (a,b) (a',b') =
  match f a a' with
  | 0 -> g b b'
  | x -> x
let compare2_by f g (a,b) (a',b') =
  match Stdlib.compare (f a) (f a') with
  | 0 -> Stdlib.compare (g b) (g b')
  | x -> x
let compare_fst f (a,_) (a',_) = f a a'

let hexdump str =
  let buf = Buffer.create 80 and num = ref 0 in
  let rec loop chars =
    match List.take 16 chars with
    | [] -> Buffer.contents buf
    | l ->
          if Buffer.length buf <> 0 then Buffer.add_char buf '\n';
          bprintf buf "%08x|  " !num;
          num := !num + 16;
          let rec bytes pos = function
            | [] ->
                blanks pos
            | x :: l ->
                if pos = 8 then Buffer.add_char buf ' ';
                Printf.bprintf buf "%02x " (Char.code x);
                bytes (pos + 1) l
          and blanks pos =
            if pos < 16 then begin
              if pos = 8 then
                Buffer.add_string buf "    "
              else
                Buffer.add_string buf "   ";
              blanks (pos + 1)
            end
          in
          bytes 0 l;
          Buffer.add_string buf " |";
          List.iter (fun ch -> Buffer.add_char buf (if ch >= '\x20' && ch <= '\x7e' then ch else '.')) l;
          Buffer.add_char buf '|';
          loop (List.drop 16 chars)
  in
   loop (String.explode str)

open Gc

let gc_diff st1 st2 =
  let allocated st = st.minor_words +. st.major_words -. st.promoted_words in
  let a = allocated st2 -. allocated st1 in
  let minor = st2.minor_collections - st1.minor_collections in
  let major = st2.major_collections - st1.major_collections in
  let compact = st2.compactions - st1. compactions in
  let heap = st2.heap_words - st1.heap_words in
  Printf.sprintf "allocated %10s, heap %10s, collection %d %d %d" (caml_words_f a) (caml_words heap) compact major minor

let gc_show name f x =
  let t = new timer in
  let st = Gc.quick_stat () in
  Std.finally (fun () -> let st2 = Gc.quick_stat () in Log.main #info "GC DIFF %s : %s, elapsed %s" name (gc_diff st st2) t#get_str) f x

let gc_settings () =
  let gc = Gc.get () in
  sprintf "minor %s incr %s major %d%% compact %d%% policy %d"
    (caml_words gc.Gc.minor_heap_size)
    (let n = gc.Gc.major_heap_increment in if n <= 1_000 then sprintf "%d%%" n else caml_words n)
    gc.Gc.space_overhead
    gc.Gc.max_overhead
    gc.Gc.allocation_policy

(*
let mem_usage v =
  let x = Objsize.objsize v in
  Printf.sprintf "%s (data %s)" (Action.bytes_string (Objsize.size_with_headers x)) (Action.bytes_string (Objsize.size_without_headers x))
*)

let count_bytes_to count out =
  IO.create_out
    ~write:(fun c -> count := Int64.succ !count; IO.write out c)
    ~output:(fun s o l -> count := Int64.add !count (Int64.of_int l); IO.output out s o l)
    ~flush:(fun () -> IO.flush out)
    ~close:(fun () -> !count)

let count_bytes out = let count = ref 0L in count_bytes_to count out

let bench ?(compact=Gc.compact) count f =
  compact ();
  let t = new timer in
  let st = Gc.quick_stat () in
  let res = Exn.map (fun () -> for _ = 1 to count do ignore @@ f () done) () in
  let st2 = Gc.quick_stat () in
  let elapsed = t#get in
  let res = match res with
  | `Ok () -> "ok"
  | `Exn exn -> "exn " ^ Exn.str exn
  in
  sprintf "%s, elapsed %s, %.2f/sec : %s" (gc_diff st st2) (Time.duration_str elapsed) (speed count elapsed) res

let run_bench ?compact count l =
  let max_len = List.fold_left (fun acc (name,_) -> max acc (String.length name)) 0 l in
  let align s = String.make (max 0 (max_len - String.length s)) ' ' ^ s in
  printfn "run_bench %d cases (count %d)" (List.length l) count;
  List.iter (fun (name,f) -> printfn "%s : %s" (align name) (bench ?compact count f)) l

(* sorting DynArray *)

let rec quick_sort d left right cmp =
  let i = ref left and j = ref right in
  let pivot = DynArray.unsafe_get d ((left + right) / 2) in
  while !i <= !j do
    while cmp (DynArray.unsafe_get d !i) pivot < 0 do incr i done;
    while cmp pivot (DynArray.unsafe_get d !j) < 0 do decr j done;
    if !i <= !j then begin
      let tmp = DynArray.unsafe_get d !i in
      DynArray.unsafe_set d !i (DynArray.unsafe_get d !j);
      DynArray.unsafe_set d !j tmp;
      incr i; decr j
    end;
  done;
  if left < !j then quick_sort d left !j cmp;
  if !i < right then quick_sort d !i right cmp

let quick_sort d ?(start=0) ?(n = DynArray.length d - start) cmp = quick_sort d start (start + n - 1) cmp

let list_min ?(cmp=compare) l =
  List.fold_left (fun x y -> if cmp x y < 0 then x else y) (List.hd l) l

let args = List.tl (Array.to_list Sys.argv)

let random_bytes ?state n = String.init n (fun _ -> Char.chr (random_int state 256))
let random_ascii ?state n = String.init n (fun _ -> Char.chr (Char.code '!' + random_int state (Char.code '~' - Char.code '!' + 1)))

let parse_bytes_unit s =
  let unit_of_string s =
    match Stre.drop_suffix (String.lowercase s) "b" with
    | "" -> 1
    | "k" -> 1024
    | "m" -> 1024 * 1024
    | "g" -> 1024 * 1024 * 1024
    | "t" -> 1024 * 1024 * 1024 * 1024
    | "p" -> 1024 * 1024 * 1024 * 1024 * 1024
    | "e" -> 1024 * 1024 * 1024 * 1024 * 1024 * 1024
    | _ -> raise Not_found
  in
  try
    if s = "0" then 0 else unit_of_string s
  with
    Not_found ->
      try
        Scanf.sscanf s "%d%s%!" (fun n t -> assert (n <> 0); n * unit_of_string t)
      with
        exn -> Exn.fail ~exn "parse_bytes_unit: %S" s

let get_bytes_unit n =
  let rec loop n l =
    match l with
    | [] -> raise Not_found
    | _::xs when n mod 1024 = 0 -> loop (n / 1024) xs
    | x::_ -> (n, x)
  in
  assert (n <> 0);
  loop n ["";"K";"M";"G";"T";"P";"E"]

let show_bytes_unit n =
  match get_bytes_unit n with
  | 1, s -> s ^ "B"
  | n, s -> (string_of_int n) ^ s

let show_bytes_unit = function
| 0 -> "0"
| n when n < 0 -> "-" ^ show_bytes_unit ~-n
| n -> show_bytes_unit n

let shell_sequence names =
  let l = ref [] in
  let fresh s =
    try
      Scanf.sscanf s "%[a-z]%[0-9]%!" (fun prefix start -> prefix, start, int_of_string start)
    with _ ->
      tuck l s;
      ("","",0)
  in
  let flush (prefix,start,last) =
    if prefix <> "" then
      tuck l @@ if int_of_string start = last then sprintf "%s%s" prefix start else sprintf "%s{%s..%d}" prefix start last
  in
  let acc = List.fold_left begin fun (prefix,start,last as acc) s ->
    match prefix with
    | "" -> fresh s
    | _ ->
      let next =
        match String.(length prefix + length start = length s && sub s 0 (length prefix) = prefix) with
        | false -> None
        | true ->
          match int_of_string String.(sub s (length prefix) (length start)) with
          | exception _ -> None
          | n when n = last + 1 -> Some (prefix,start,n)
          | _ -> None
      in
      match next with
      | Some acc -> acc
      | None -> flush acc; fresh s
  end ("","",0) names
  in
  flush acc;
  List.rev !l
