(* Copyright (C) 2014--2017  Petter A. Urkedal <paurkedal@gmail.com>
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or (at your
 * option) any later version, with the OCaml static compilation exception.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *)

open Caqti1_describe
open Caqti1_errors
open Caqti_prereq
open Caqti1_query
open Caqti1_sigs
open Printf
open Sqlite3

module CL = CalendarLib
let with_utc f = CL.Time_Zone.(on f UTC ())

(* TODO: Implement tuple-debugging. *)

let typedesc_of_decltype = function
  | None -> `Unknown
  | Some s ->
    (* CHECKME: Can NOT NULL or other specifiers occur here? *)
    let lparen = try String.index s '(' with Not_found -> String.length s in
    (match String.lowercase_ascii (String.sub s 0 lparen) with
     | "integer" -> `Int
     | "float" -> `Float
     | "text" | "varchar" -> `String
     | "blob" -> `Bytes
     | "date" -> `Date
     | "timestamp" -> `Utc
     | _ -> `Other s)

let typename_of_data = function
  | Data.NONE -> "none"
  | Data.NULL -> "null"
  | Data.INT _ -> "int"
  | Data.FLOAT _ -> "float"
  | Data.TEXT _ -> "text"
  | Data.BLOB _ -> "blob"

module Q = struct
  let start = Caqti1_query.prepare_sql "BEGIN"
  let commit = Caqti1_query.prepare_sql "COMMIT"
  let rollback = Caqti1_query.prepare_sql "ROLLBACK"
end

module Param = struct
  open Sqlite3.Data
  type t = Data.t
  let null = NULL
  let option f = function None -> NULL | Some x -> f x
  let bool = function false -> INT Int64.zero | true -> INT Int64.one
  let int x = INT (Int64.of_int x)
  let int32 x = INT (Int64.of_int32 x)
  let int64 x = INT x
  let float x = FLOAT x
  let string x = TEXT x
  let bytes x = BLOB (Bytes.to_string x)
  let date_string x = TEXT x
  let date_tuple x = TEXT (iso8601_of_datetuple x)
  let date_cl x = TEXT (CL.Printer.Date.sprint "%F" x)
  let utc_float x =
    let t = CL.Calendar.from_unixfloat x in
    TEXT (with_utc (fun () -> CL.Printer.Calendar.sprint "%F %T" t))
  let utc_string x = TEXT x
  let utc_cl x = TEXT (with_utc (fun () -> CL.Printer.Calendar.sprint "%F %T" x))
end

let params_info ps = Array.to_list (Array.map Data.to_string_debug ps)

let invalid_decode typename i stmt =
  let typename' = typename_of_data (Sqlite3.column stmt i) in
  let msg =
    sprintf "Expected %s but received %s for column %d of Sqlite result."
            typename typename' i in
  raise (Invalid_argument msg)

module Tuple = struct
  open Sqlite3.Data
  type t = stmt
  let length = Sqlite3.column_count
  let is_null i stmt =
    match Sqlite3.column stmt i with NONE | NULL -> true | _ -> false
  let option f i stmt =
    match Sqlite3.column stmt i with NONE | NULL -> None | _ -> Some (f i stmt)
  let bool i stmt =
    match Sqlite3.column stmt i with
    | INT x when x = Int64.zero -> false
    | INT x when x = Int64.one -> true
    | _ -> invalid_decode "bool" i stmt
  let int i stmt =
    match Sqlite3.column stmt i with
    | INT x -> Int64.to_int x
    | _ -> invalid_decode "int" i stmt
  let int32 i stmt =
    match Sqlite3.column stmt i with
    | INT x -> Int64.to_int32 x
    | _ -> invalid_decode "int" i stmt
  let int64 i stmt =
    match Sqlite3.column stmt i with
    | INT x -> x
    | _ -> invalid_decode "int" i stmt
  let float i stmt =
    match Sqlite3.column stmt i with
    | FLOAT x -> x
    | INT x -> Int64.to_float x
    | _ -> invalid_decode "float" i stmt
  let string i stmt =
    match Sqlite3.column stmt i with
    | TEXT x -> x
    | _ -> invalid_decode "string" i stmt
  let bytes i stmt =
    match Sqlite3.column stmt i with
    | BLOB x -> Bytes.of_string x
    | _ -> invalid_decode "bytes" i stmt
  let date_string i stmt =
    match Sqlite3.column stmt i with
    | TEXT x -> x
    | _ -> invalid_decode "date" i stmt
  let date_tuple i stmt =
    match Sqlite3.column stmt i with
    | TEXT x -> datetuple_of_iso8601 x
    | _ -> invalid_decode "date" i stmt
  let date_cl i stmt =
    match Sqlite3.column stmt i with
    | TEXT x -> CL.Printer.Date.from_fstring "%F" x
    | _ -> invalid_decode "date" i stmt
  let utc_float i stmt =
    match Sqlite3.column stmt i with
    | TEXT x ->
      CL.Calendar.to_unixfloat
        (with_utc (fun () -> CL.Printer.Calendar.from_fstring "%F %T" x))
    | _ -> invalid_decode "timestamp" i stmt
  let utc_string i stmt =
    match Sqlite3.column stmt i with
    | TEXT x -> x
    | _ -> invalid_decode "timestamp" i stmt
  let utc_cl i stmt =
    match Sqlite3.column stmt i with
    | TEXT x -> with_utc (fun () -> CL.Printer.Calendar.from_fstring "%F %T" x)
    | _ -> invalid_decode "timestamp" i stmt
end

(*
module Report = struct
  type t = Sqlite3.db
  let returned_count = None
  let affected_count = Some (fun db -> Sqlite3.changes db)
end
*)

let yield = Thread.yield

module Connect_functor (System : Caqti1_system_sig.S) = struct
  open System

  module type CONNECTION = CONNECTION with type 'a io = 'a System.io

  type 'a io = 'a System.io

  let driver_info =
    Caqti_driver_info.create
      ~uri_scheme:"sqlite3"
      ~dialect_tag:`Sqlite
      ~parameter_style:(`Linear "?")
      ~can_pool:false
      ~can_concur:false
      ~can_transact:true
      ~describe_has_typed_params:false
      ~describe_has_typed_fields:true
      ()

  let query_info = make_query_info driver_info

  let connect uri =

    (* Check URI *)

    assert (Uri.scheme uri = Some "sqlite3");

    begin match Uri.userinfo uri, Uri.host uri with
    | None, (None | Some "") -> return ()
    | _ -> fail (Invalid_argument "Sqlite URI cannot contain user or host \
                                   components.")
    end >>= fun () ->

    (* Determine mode *)

    let get_bool name =
      (match Uri.get_query_param uri name with
       | Some ("true" | "yes") -> return (Some true)
       | Some ("false" | "no") -> return (Some false)
       | Some _ ->
          let msg = sprintf "The %s parameter is boolean." name in
          fail (Connect_failed (uri, msg))
       | None -> return None) in
    begin
      get_bool "write" >>= fun write ->
      get_bool "create" >>= fun create ->
      (match write, create with
       | Some false, Some true ->
          fail (Connect_failed (uri, "Create mode presumes write."))
       | (Some false), (Some false | None)      -> return (Some `READONLY)
       | (Some true | None), (Some true | None) -> return (None)
       | (Some true | None), (Some false)       -> return (Some `NO_CREATE))
    end >>= fun mode ->

    (* Database Handle *)

    let db_mutex = Mutex.create () in
    let db = Sqlite3.db_open ?mode (Uri.path uri |> Uri.pct_decode) in
    begin
      try
        Sqlite3.busy_timeout db
          (int_of_string (Sys.getenv "CAQTUS_SQLITE3_BUSY_TIMEOUT"))
      with Not_found -> ()
    end;

    let with_db f =
      Preemptive.detach begin fun () ->
        Mutex.lock db_mutex;
        finally (fun () -> Mutex.unlock db_mutex) (fun () -> f db)
      end () in

    let close_db () = with_db @@ fun db ->
      while not (Sqlite3.db_close db) do yield () done in

    (* Helpers *)

    let raise_rc q rc =
      raise (Execute_failed (uri, query_info q, Sqlite3.Rc.to_string rc)) in

    let prim_exec extract q params =
      (if Log.debug_query_enabled ()
       then Log.debug_query (query_info q) (params_info params)
       else return ()) >>= fun () ->
      begin match q with
      | Prepared {pq_encode} ->
        begin try return (pq_encode driver_info)
        with Missing_query_string ->
          fail (Prepare_failed
                  (uri, query_info q, "Missing query string for SQLite."))
        end
      | Oneshot qsf -> return (qsf driver_info)
      end >>= fun qs ->
      with_db begin fun db ->
        let stmt =
          try Sqlite3.prepare db qs with
          | Sqlite3.Error msg ->
            raise (Prepare_failed (uri, query_info q, msg)) in
        finally (fun () -> ignore (Sqlite3.finalize stmt))
          begin fun () ->
            for i = 0 to Array.length params - 1 do
              match Sqlite3.bind stmt (i + 1) params.(i) with
              | Sqlite3.Rc.OK -> ()
              | rc ->
                raise (Prepare_failed
                        (uri, query_info q, Sqlite3.Rc.to_string rc))
            done;
            extract stmt
          end
      end in

    (* The Module *)

    return (module struct
      type 'a io = 'a System.io
      type param = Data.t
      type tuple = stmt

      module Param = Param
      module Tuple = Tuple

      let uri = uri
      let driver_info = driver_info

      let disconnect () = close_db ()
      let validate () = return true
      let check f = f true

      let describe = Some (fun q ->
        let extract stmt =
          let desc_field i =
            Sqlite3.column_name stmt i,
            typedesc_of_decltype (Sqlite3.column_decltype stmt i) in
          let n_params = Sqlite3.bind_parameter_count stmt in
          let n_fields = Sqlite3.column_count stmt in
          { querydesc_params = Array.make n_params `Unknown;
            querydesc_fields = Array.init n_fields desc_field } in
        prim_exec extract q [||])

      let exec q params =
        let extract stmt =
          match Sqlite3.step stmt with
          | Sqlite3.Rc.DONE -> ()
          | rc -> raise_rc q rc in
        prim_exec extract q params

      let find q f params =
        let rec extract stmt =
          match Sqlite3.step stmt with
          | Sqlite3.Rc.DONE ->
            let msg = "Received no tuples, expected one." in
            raise (Miscommunication (uri, query_info q, msg))
          | Sqlite3.Rc.ROW ->
            let r = f stmt in
            begin match Sqlite3.step stmt with
            | Sqlite3.Rc.DONE -> r
            | Sqlite3.Rc.ROW ->
              let msg = "Received multiple tuples, expected one." in
              raise (Miscommunication (uri, query_info q, msg))
            | rc -> raise_rc q rc
            end
          | rc -> raise_rc q rc in
        prim_exec extract q params

      let find_opt q f params =
        let rec extract stmt =
          match Sqlite3.step stmt with
          | Sqlite3.Rc.DONE -> None
          | Sqlite3.Rc.ROW ->
            let r = f stmt in
            begin match Sqlite3.step stmt with
            | Sqlite3.Rc.DONE -> Some r
            | Sqlite3.Rc.ROW ->
              raise (Miscommunication
                      (uri, query_info q,
                       "Expected at most one tuple response."))
            | rc -> raise_rc q rc
            end
          | Sqlite3.Rc.BUSY | Sqlite3.Rc.LOCKED -> yield (); extract stmt
          | rc -> raise_rc q rc in
        prim_exec extract q params

      let fold q f params acc =
        let rec extract stmt =
          let rec loop acc =
            match Sqlite3.step stmt with
            | Sqlite3.Rc.DONE -> acc
            | Sqlite3.Rc.ROW -> loop (f stmt acc)
            | Sqlite3.Rc.BUSY | Sqlite3.Rc.LOCKED -> yield (); loop acc
            | rc -> raise_rc q rc in
          loop acc in
        prim_exec extract q params

      let fold_s q f params acc =
        let rec extract stmt =
          let rec loop acc =
            match Sqlite3.step stmt with
            | Sqlite3.Rc.DONE -> acc
            | Sqlite3.Rc.ROW ->
              let m = f stmt acc in
              loop (Preemptive.run_in_main (fun () -> m))
            | Sqlite3.Rc.BUSY | Sqlite3.Rc.LOCKED -> yield (); loop acc
            | rc -> raise_rc q rc in
          loop acc in
        prim_exec extract q params

      let iter_s q f params =
        let rec extract stmt =
          let rec loop () =
            match Sqlite3.step stmt with
            | Sqlite3.Rc.DONE -> ()
            | Sqlite3.Rc.ROW ->
              let m = f stmt in
              Preemptive.run_in_main (fun () -> m); loop ()
            | Sqlite3.Rc.BUSY | Sqlite3.Rc.LOCKED -> yield (); loop ()
            | rc -> raise_rc q rc in
          loop () in
        prim_exec extract q params

      let iter_p = iter_s (* TODO *)

      let start () = exec Q.start [||]
      let commit () = exec Q.commit [||]
      let rollback () = exec Q.rollback [||]
    end : CONNECTION)

end

let () = Caqti1_connect.define_driver "sqlite3" (module Connect_functor)
