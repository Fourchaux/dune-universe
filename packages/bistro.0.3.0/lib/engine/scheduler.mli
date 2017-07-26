open Core_kernel.Std
open Rresult
open Bistro_tdag

module DAG : Tdag_sig.S
  with type task = Task.t


type time = float

type event =
  | Init of { dag : DAG.t ; needed : Task.t list ; already_done : Task.t list }
  | Task_ready of Task.t
  | Task_started of Task.t * Allocator.resource
  | Task_ended of Task.result
  | Task_skipped of Task.t * [ `Done_already
                             | `Missing_dep
                             | `Allocation_error of string]

class type logger = object
  method event : Task.config -> time -> event -> unit
  method stop : unit
  method wait4shutdown : unit Lwt.t
end

type trace =
  | Run of { ready : time ;
             start : time ;
             end_ : time ;
             outcome : Task.result }

  | Skipped of [ `Done_already
               | `Missing_dep
               | `Allocation_error of string ]

val compile :
  Bistro.any_workflow list ->
  DAG.t * Task.t list

val run :
  ?logger:logger ->
  ?goals:Task.t list ->
  Task.config ->
  Allocator.t ->
  DAG.t ->
  trace String.Map.t Lwt.t
