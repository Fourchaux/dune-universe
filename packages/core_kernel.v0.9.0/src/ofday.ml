open! Import
open Std_internal
open Digit_string_helpers

(* Create an abstract type for Ofday to prevent us from confusing it with
   other floats.
*)
module Stable = struct
  module V1 = struct
    module T : sig
      type underlying = float
      type t = private underlying [@@deriving bin_io, hash]
      include Comparable.S_common  with type t := t
      include Comparable.With_zero with type t := t
      include Robustly_comparable  with type t := t
      include Floatable            with type t := t
      val add                        : t -> Span.t -> t option
      val sub                        : t -> Span.t -> t option
      val next                       : t -> t option
      val prev                       : t -> t option
      val diff                       : t -> t -> Span.t
      val of_span_since_start_of_day : Span.t -> t
      val to_span_since_start_of_day : t -> Span.t
      val start_of_day               : t
    end = struct
      (* Number of seconds since midnight. *)
      type underlying = Float.t
      include
        (Float : sig
           type t = underlying [@@deriving bin_io, hash]
           include Comparable.S_common  with type t := t
           include Comparable.With_zero with type t := t
           include Robustly_comparable  with type t := t
           include Floatable            with type t := t
         end)
      (* IF THIS REPRESENTATION EVER CHANGES, ENSURE THAT EITHER
         (1) all values serialize the same way in both representations, or
         (2) you add a new Time.Ofday version to stable.ml *)

      (* due to precision limitations in float we can't expect better than microsecond
         precision *)
      include Float.Robust_compare.Make
          (struct let robust_comparison_tolerance = 1E-6 end)

      let to_span_since_start_of_day t = Span.of_sec t

      (* Another reasonable choice would be only allowing Ofday.t to be < 24hr, but this
         choice was made early on and people became used to being able to easily call 24hr
         the end of the day.  It's a bit sad because it shares that moment with the
         beginning of the next day, and round trips oddly if passed through
         Time.to_date_ofday/Time.of_date_ofday.

         Note: [Schedule.t] requires that the end of day be representable, as it's the
         only way to write a schedule in terms of [Ofday.t]s that spans two weekdays. *)
      (* ofday must be >= 0 and <= 24h *)
      let is_valid (t:t) =
        let t = to_span_since_start_of_day t in
        Span.(<=) Span.zero t && Span.(<=) t Span.day
      ;;

      let of_span_since_start_of_day span =
        let module C = Float.Class in
        let s = Span.to_sec span in
        match Float.classify s with
        | C.Infinite -> invalid_arg "Ofday.of_span_since_start_of_day: infinite value"
        | C.Nan      -> invalid_arg "Ofday.of_span_since_start_of_day: NaN value"
        | C.Normal | C.Subnormal | C.Zero ->
          if not (is_valid s) then
            invalid_argf "Ofday out of range: %f" s ()
          else
            s
      ;;

      let start_of_day = 0.

      let add (t:t) (span:Span.t) =
        let t = t +. (Span.to_sec span) in
        if is_valid t then Some t else None

      let sub (t:t) (span:Span.t) =
        let t = t -. (Span.to_sec span) in
        if is_valid t then Some t else None

      let next t =
        let candidate = Float.one_ulp `Up t in
        if is_valid candidate
        then Some candidate
        else None
      ;;

      let prev t =
        let candidate = Float.one_ulp `Down t in
        if is_valid candidate
        then Some candidate
        else None
      ;;

      let diff t1 t2 =
        Span.(-) (to_span_since_start_of_day t1) (to_span_since_start_of_day t2)
    end

    (* [create] chops off any subsecond part when [sec = 60] to handle leap seconds. In
       particular it's trying to be generous about reading in times on things like fix
       messages that might include an extra unlikely second.

       Other ways of writing a time, like 1000ms, while mathematically valid, don't match
       ways that people actually write times down, so we didn't see the need to support
       them. That is, a clock might legitimately read 23:59:60 (or, with 60 seconds at
       times of day other than 23:59, depending on the time zone), but it doesn't seem
       reasonable for a clock to read "23:59:59 and 1000ms". *)
    let create ?hr ?min ?sec ?ms ?us () =
      let sec, ms, us =
        match sec with
        | Some 60 -> Some 60, Some 0, Some 0
        | _       -> sec, ms, us
      in
      T.of_span_since_start_of_day (Span.create ?hr ?min ?sec ?ms ?us ())
    ;;

    let%test "create can handle a leap second" =
      let last_second = create ~hr:21 () in
      List.for_all
        ~f:(fun v -> v = last_second)
        [ create ~hr:20 ~min:59 ~sec:60 ()
        ; create ~hr:20 ~min:59 ~sec:60 ~ms:500 ()
        ; create ~hr:20 ~min:59 ~sec:60 ~ms:500 ~us:500 ()
        ; create ~hr:20 ~min:59 ~sec:60 ~ms:0 ~us:500 () ]
    ;;

    let to_parts t = Span.to_parts (T.to_span_since_start_of_day t)

    let to_string_gen ~drop_ms ~drop_us ~trim x =
      assert (if drop_ms then drop_us else true);
      let module P = Span.Parts in
      let parts = to_parts x in
      let dont_print_us = drop_us || (trim && parts.P.us = 0) in
      let dont_print_ms = drop_ms || (trim && parts.P.ms = 0 && dont_print_us) in
      let dont_print_s  = trim && parts.P.sec = 0 && dont_print_ms in
      let len =
        if dont_print_s then 5
        else if dont_print_ms then 8
        else if dont_print_us then 12
        else 15
      in
      let buf = String.create len in
      blit_string_of_int_2_digits buf ~pos:0 parts.P.hr;
      buf.[2] <- ':';
      blit_string_of_int_2_digits buf ~pos:3 parts.P.min;
      if dont_print_s then ()
      else begin
        buf.[5] <- ':';
        blit_string_of_int_2_digits buf ~pos:6 parts.P.sec;
        if dont_print_ms then ()
        else begin
          buf.[8] <- '.';
          blit_string_of_int_3_digits buf ~pos:9 parts.P.ms;
          if dont_print_us then ()
          else
            blit_string_of_int_3_digits buf ~pos:12 parts.P.us
        end
      end;
      buf
    ;;

    let to_string_trimmed t = to_string_gen ~drop_ms:false ~drop_us:false ~trim:true t

    let to_sec_string t = to_string_gen ~drop_ms:true ~drop_us:true ~trim:false t

    let to_millisec_string t = to_string_gen ~drop_ms:false ~drop_us:true ~trim:false t

    let of_string_iso8601_extended ?pos ?len str =
      let (pos, len) =
        match
          Ordered_collection_common.get_pos_len ?pos ?len ~length:(String.length str)
        with
        | Result.Ok z    -> z
        | Result.Error s -> failwithf "Ofday.of_string_iso8601_extended: %s" s ()
      in
      try
        if len < 2 then failwith "len < 2"
        else begin
          let span =
            let hour = parse_two_digits str pos in
            if hour > 24 then failwith "hour > 24";
            let span = Span.of_hr (float hour) in
            if len = 2 then span
            else if len < 5 then failwith "2 < len < 5"
            else if str.[pos + 2] <> ':' then failwith "first colon missing"
            else
              let minute = parse_two_digits str (pos + 3) in
              if minute >= 60 then failwith "minute > 60";
              let span = Span.(+) span (Span.of_min (float minute)) in
              if hour = 24 && minute <> 0 then
                failwith "24 hours and non-zero minute";
              if len = 5 then span
              else if len < 8 then failwith "5 < len < 8"
              else if str.[pos + 5] <> ':' then failwith "second colon missing"
              else
                let second = parse_two_digits str (pos + 6) in
                (* second can be 60 in the case of a leap second. Unfortunately, what with
                   non-hour-multiple timezone offsets, we can't say anything about what
                   the hour or minute must be in that case *)
                if second > 60
                then failwithf "invalid second: %i" second ();
                if hour = 24 && second <> 0 then
                  failwith "24 hours and non-zero seconds";
                let seconds = Span.of_sec (float second) in
                if len = 8 then Span.(+) span seconds
                else if len = 9 then failwith "length = 9"
                else
                  match str.[pos + 8] with
                  | '.' | ',' ->
                    let last = pos + len - 1 in
                    let rec loop pos subs =
                      let subs = subs * 10 + Char.get_digit_exn str.[pos] in
                      if pos = last then subs else loop (pos + 1) subs
                    in
                    let subs = loop (pos + 9) 0 in
                    if hour = 24 && subs <> 0 then
                      failwith "24 hours and non-zero subseconds";
                    let seconds =
                      Span.(+)
                        seconds
                        (Span.of_sec (float subs /. (10. ** float (len - 9))))
                    in
                    (* above we test for a leap second, but we can't represent the leap
                       second within an Ofday.t, so here we are forced to trim it back
                       if we have more than 60 seconds. *)
                    let seconds =
                      if Span.(>) seconds (Span.of_sec 60.)
                      then Span.of_sec 60.
                      else seconds
                    in
                    Span.(+) span seconds
                  | _ -> failwith "missing subsecond separator"
          in
          T.of_span_since_start_of_day span
        end
      with exn ->
        invalid_argf "Ofday.of_string_iso8601_extended(%s): %s"
          (String.sub str ~pos ~len) (Exn.to_string exn) ()
    ;;

    let%test "of_string_iso8601_extended supports leap seconds" =
      let last_second = create ~hr:21 () in
      List.for_all
        ~f:(fun s -> of_string_iso8601_extended s = last_second)
        [ "20:59:60"
        ; "20:59:60.500"
        ; "20:59:60.000" ]
    ;;

    let%test "of_string_iso8601_extended doesn't support two leap seconds" =
      Exn.does_raise (fun () -> of_string_iso8601_extended "23:59:61")

    let small_diff =
      let hour = 3600. in
      (fun ofday1 ofday2 ->
         let ofday1 = Span.to_sec (T.to_span_since_start_of_day ofday1) in
         let ofday2 = Span.to_sec (T.to_span_since_start_of_day ofday2) in
         let diff   = ofday1 -. ofday2 in
         (*  d1 is in (-hour; hour) *)
         let d1 = Float.mod_float diff hour in
         (*  d2 is in (0;hour) *)
         let d2 = Float.mod_float (d1 +. hour) hour in
         let d = if d2 > hour /. 2. then d2 -. hour else d2 in
         Span.of_sec d)
    ;;

    (* There are a number of things that would be shadowed by this include because of the
       scope of Constrained_float.  These need to be defined below.  It's a an unfortunate
       situation because we would like to say include T, without shadowing. *)
    include T

    let to_string t = to_string_gen ~drop_ms:false ~drop_us:false ~trim:false t

    include Pretty_printer.Register (struct
        type nonrec t = t
        let to_string = to_string
        let module_name = "Core_kernel.Time.Ofday"
      end)

    (* lifted allowed meridiem suffixes out so that tests can reuse them *)
    let plus_lowercase xs = xs @ List.map xs ~f:String.lowercase
    let ante = lazy (plus_lowercase ["AM";"A";"A.M";"A.M."])
    let post = lazy (plus_lowercase ["PM";"P";"P.M";"P.M."])

    let of_string s =
      try
        let prefix, meridiem =
          let chop_suffixes s ~suffixes:lst =
            List.find_map lst ~f:(fun suffix -> String.chop_suffix s ~suffix)
          in
          match chop_suffixes s ~suffixes:(Lazy.force ante) with
          | Some prefix -> String.rstrip prefix, Some `AM
          | None ->
            match chop_suffixes s ~suffixes:(Lazy.force post) with
            | Some prefix -> String.rstrip prefix, Some `PM
            | None -> s, None
        in
        let h, m, s =
          match String.split prefix ~on:':' with
          | [h; m; s] -> (h, m, Float.of_string s)
          | [h; m]    -> (h, m, 0.)
          | [hm]      ->
            if Option.is_some meridiem
            then (hm, "00", 0.)
            else if Int.(=) (String.length hm) 4
            then ((String.sub hm ~pos:0 ~len:2), (String.sub hm ~pos:2 ~len:2), 0.)
            else failwith "No colon, expected string of length four"
          | _ -> failwith "More than two colons"
        in
        let h =
          let h = Int.of_string h in
          match meridiem with
          | None -> h
          | Some am_or_pm ->
            (if Int.(>) h 12
             then failwith "hour must be <= 12 when AM/PM is specified");
            (if Int.(=) h 0
             then failwith "hour must be > 0 when AM/PM is specified");
            match am_or_pm with
            | `AM -> if Int.(=) h 12 then 0 else h
            | `PM -> if Int.(=) h 12 then 12 else Int.(+) h 12
        in
        let m = Int.of_string m in
        let is_end_of_day = Int.(h = 24 && m = 0) && Float.(s = 0.) in
        if not (Int.(h <= 23 && h >= 0) || is_end_of_day) then
          failwithf "hour out of valid range: %i" h ();
        if not Int.(m <= 59 && m >= 0) then
          failwithf "minutes out of valid range: %i" m ();
        let s =
          if Float.(0. <= s && s < 60.)
          then s
          else if Float.(s < 61.) (* allow a leap second *)
          then 60.
          else failwithf "seconds out of valid range: %g" s ();
        in
        (* create takes integer arguments for each field, and so we have to use add
           to get float seconds onto the value. *)
        Option.value_exn (add (create ~hr:h ~min:m ()) (Span.of_sec s))
      with exn ->
        invalid_argf "Ofday.of_string (%s): %s" s (Exn.to_string exn) ()
    ;;

    let%bench "Time.Ofday.of_string" = of_string "12:00:00am"

    let%test "of_string supports leap seconds" =
      let last_second = create ~hr:21 () in
      List.for_all
        ~f:(fun s -> of_string s = last_second)
        [ "20:59:60"
        ; "20:59:60.500"
        ; "20:59:60.000" ]
    ;;

    let%test_unit "of_string supports non-meridiem times" =
      assert (create ~hr:7 ~min:21 ~sec:0 () = of_string "07:21:00")
    ;;

    let%test_unit "of_string supports meridiem times" =
      let test_excluding_noon ~hr ~zeroes ~meridiem () =
        let hrs_to_add, suffixes =
          let plus_space xs = xs @ List.map xs ~f:(fun x -> " " ^ x) in
          match meridiem with
          | None     -> 0,  [""]
          | Some `AM -> 0,  plus_space (Lazy.force ante)
          | Some `PM -> 12, plus_space (Lazy.force post)
        in
        List.iter suffixes ~f:(fun suffix ->
          let t = create ~hr:(hr + hrs_to_add) () in
          let str = sprintf "%d%s%s" hr zeroes suffix in
          assert (t = (of_string str)));
      in
      let failure f = assert (Option.is_none (Option.try_with f)) in
      let success f =
        match Or_error.try_with f with
        | Ok _ -> ()
        | Error e -> Error.raise (Error.tag e ~tag:"expected success")
      in
      (* Test everything but hour 12 and 0 *)
      let first_half_of_day_except_0_and_12 = [1;2;3;4;5;6;7;8;9;10;11] in
      let second_half_of_day = [13;14;15;16;17;18;19;21;21;22;23;24] in
      (* 1 -> 11 are tested here, simplistically by adding 12 when
         [meridiem is `PM]. We test ~hr:12 later *)
      List.iter first_half_of_day_except_0_and_12 ~f:(fun hr ->
        (* Test X:00:00am, X:00am. amd Xam *)
        success (test_excluding_noon ~hr ~zeroes:":00:00" ~meridiem:(Some `AM));
        success (test_excluding_noon ~hr ~zeroes:":00"    ~meridiem:(Some `AM));
        success (test_excluding_noon ~hr ~zeroes:""       ~meridiem:(Some `AM));
        success (test_excluding_noon ~hr ~zeroes:":00:00" ~meridiem:(Some `AM));
        success (test_excluding_noon ~hr ~zeroes:":00"    ~meridiem:(Some `PM));
        success (test_excluding_noon ~hr ~zeroes:""       ~meridiem:(Some `PM));
        (* "11pm" is fine, but "11" is not a valid ofday *)
        failure (test_excluding_noon ~hr ~zeroes:""       ~meridiem:None);
      );
      (* None of hour 13 -> 24 should support AM or PM *)
      List.iter second_half_of_day ~f:(fun hr ->
        failure (test_excluding_noon ~zeroes:":00:00" ~hr ~meridiem:(Some `AM));
        failure (test_excluding_noon ~zeroes:":00"    ~hr ~meridiem:(Some `AM));
        failure (test_excluding_noon ~zeroes:""       ~hr ~meridiem:(Some `AM));
        failure (test_excluding_noon ~zeroes:":00:00" ~hr ~meridiem:(Some `PM));
        failure (test_excluding_noon ~zeroes:":00"    ~hr ~meridiem:(Some `PM));
        failure (test_excluding_noon ~zeroes:""       ~hr ~meridiem:(Some `PM));
      );
      List.iter ([0;12] @ first_half_of_day_except_0_and_12 @ second_half_of_day)
        ~f:(fun hr ->
          success (test_excluding_noon ~hr ~zeroes:":00:00" ~meridiem:None);
          success (test_excluding_noon ~hr ~zeroes:":00"    ~meridiem:None);
          failure (test_excluding_noon ~hr ~zeroes:""       ~meridiem:None);
        );
      (* Test hour 12 *)
      assert ((create ~hr:12 ()) = (of_string "12:00:00 PM"));
      assert ((create ~hr:0 ())  = (of_string "12:00:00 AM"));
      (* Can't have a 0'th hour ofday with a meridiem suffix *)
      failure (fun () -> (of_string "00:00:00 AM"));
      failure (fun () -> (of_string "00:00:00 PM"));
    ;;

    let t_of_sexp sexp =
      match sexp with
      | Sexp.Atom s ->
        begin try
          of_string s
        with
        | Invalid_argument s -> of_sexp_error ("Ofday.t_of_sexp: " ^ s) sexp
        end
      | _ -> of_sexp_error "Ofday.t_of_sexp" sexp
    ;;

    let sexp_of_t span = Sexp.Atom (to_string span)
  end
end

include Stable.V1

include Hashable.Make_binable (struct
    type nonrec t = t [@@deriving bin_io, compare, hash, sexp_of]

    (* Previous versions rendered hash-based containers using float serialization rather
       than time serialization, so when reading hash-based containers in we accept either
       serialization. *)
    let t_of_sexp sexp =
      match Float.t_of_sexp sexp with
      | float       -> of_float float
      | exception _ -> t_of_sexp sexp
  end)

module C = struct

  type t = T.t [@@deriving bin_io]

  type comparator_witness = T.comparator_witness

  let comparator = T.comparator

  (* In 108.06a and earlier, ofdays in sexps of Maps and Sets were raw floats.  From
     108.07 through 109.13, the output format remained raw as before, but both the raw and
     pretty format were accepted as input.  From 109.14 on, the output format was changed
     from raw to pretty, while continuing to accept both formats.  Once we believe most
     programs are beyond 109.14, we will switch the input format to no longer accept
     raw. *)
  let sexp_of_t = sexp_of_t

  let t_of_sexp sexp =
    match Option.try_with (fun () -> T.of_float (Float.t_of_sexp sexp)) with
    | Some t -> t
    | None -> t_of_sexp sexp
  ;;
end

module Map = Map.Make_binable_using_comparator (C)
module Set = Set.Make_binable_using_comparator (C)

let%test _ =
  Set.equal (Set.of_list [start_of_day])
    (Set.t_of_sexp (Sexp.List [Float.sexp_of_t (to_float start_of_day)]))
;;
