(* (c) 2018 Hannes Mehnert, all rights reserved *)

val conn_metrics : string -> [ `Close | `Open ] -> unit

val set_tmpdir : Fpath.t -> unit

type service = [ `Console | `Log | `Stats | `Vmmd ]

val socket_path : service -> string
val pp_socket : service Fmt.t

module IS : sig
  include Set.S with type elt = int
end

module IM : sig
  include Map.S with type key = int
end

module Name : sig
  type t

  val is_root : t -> bool
  val equal : t -> t -> bool

  val image_file : t -> Fpath.t
  val fifo_file : t -> Fpath.t

  val of_list : string list -> (t, [> `Msg of string ]) result
  val to_list : t -> string list
  val drop : t -> t
  val drop_front : t -> t
  val append : string -> t -> (t, [> `Msg of string ]) result
  val prepend : string -> t -> (t, [> `Msg of string ]) result
  val append_exn : string -> t -> t
  val concat : t -> t -> t

  val root : t
  val valid_label : string -> bool
  val to_string : t -> string
  val of_string : string -> (t, [> `Msg of string ]) result
  val drop_super : super:t -> sub:t -> t option
  val is_sub : super:t -> sub:t -> bool
  val domain : t -> t
  val pp : t Fmt.t
  val block_name : t -> string -> t

  val mac : t -> string -> Macaddr.t
(** [mac t bridge] outputs deterministically a mac address for [t] on [bridge].
    The resulting mac address is computed as follows: as prefix, the (no longer
    active) 00:80:41 (VEB Kombinat Robotron) is used, the remaining three bytes
    are the first three bytes of the MD5 digest of [bridge ^ "." ^ to_string t].

    i.e., [mac ["foo";"bar"] "default" = 00:80:41:1b:11:78] *)
end

module Policy : sig
  type t = {
    vms : int;
    cpuids : IS.t;
    memory : int;
    block : int option;
    bridges : Astring.String.Set.t;
  }

  val equal : t -> t -> bool

  val pp : t Fmt.t
end

module Unikernel : sig
  type typ = [ `Solo5 ]
  val pp_typ : typ Fmt.t

  type fail_behaviour = [ `Quit | `Restart of IS.t option ]

  type config = {
    typ : typ ;
    compressed : bool ;
    image : Cstruct.t ;
    fail_behaviour : fail_behaviour;
    cpuid : int ;
    memory : int ;
    block_devices : (string * string option) list ;
    bridges : (string * string option) list ;
    argv : string list option ;
  }

  val bridges : config -> string list

  val pp_config : config Fmt.t

  val restart_handler : config -> bool

  type t = {
    config : config;
    cmd : Bos.Cmd.t;
    pid : int;
    taps : string list;
    digest : Cstruct.t;
  }

  val pp : t Fmt.t

  type info = {
    typ : typ ;
    fail_behaviour : fail_behaviour;
    cpuid : int ;
    memory : int ;
    block_devices : (string * string option) list ;
    bridges : (string * string option) list ;
    argv : string list option ;
    digest : Cstruct.t ;
  }

  val info : t -> info

  val pp_info : info Fmt.t

end

module Stats : sig
  type rusage = {
    utime : int64 * int;
    stime : int64 * int;
    maxrss : int64;
    ixrss : int64;
    idrss : int64;
    isrss : int64;
    minflt : int64;
    majflt : int64;
    nswap : int64;
    inblock : int64;
    outblock : int64;
    msgsnd : int64;
    msgrcv : int64;
    nsignals : int64;
    nvcsw : int64;
    nivcsw : int64;
  }
  val pp_rusage : rusage Fmt.t
  val pp_rusage_mem : rusage Fmt.t

  type kinfo_mem = {
    vsize : int64 ;
    rss : int64 ;
    tsize : int64 ;
    dsize : int64 ;
    ssize : int64 ;
    runtime : int64 ;
    cow : int ;
    start : (int64 * int) ;
  }

  val pp_kinfo_mem : kinfo_mem Fmt.t

  type vmm = (string * int64) list
  val pp_vmm : vmm Fmt.t
  val pp_vmm_mem : vmm Fmt.t

  type ifdata = {
    bridge : string;
    flags : int32;
    send_length : int32;
    max_send_length : int32;
    send_drops : int32;
    mtu : int32;
    baudrate : int64;
    input_packets : int64;
    input_errors : int64;
    output_packets : int64;
    output_errors : int64;
    collisions : int64;
    input_bytes : int64;
    output_bytes : int64;
    input_mcast : int64;
    output_mcast : int64;
    input_dropped : int64;
    output_dropped : int64;
  }
  val pp_ifdata : ifdata Fmt.t

  type t = rusage * kinfo_mem option * vmm option * ifdata list
  val pp : t Fmt.t
end

type process_exit = [ `Exit of int | `Signal of int | `Stop of int ]

val pp_process_exit : process_exit Fmt.t

val should_restart : Unikernel.config -> Name.t -> process_exit -> bool

module Log : sig
  type log_event = [
    | `Login of Name.t * Ipaddr.V4.t * int
    | `Logout of Name.t * Ipaddr.V4.t * int
    | `Startup
    | `Unikernel_start of Name.t * Cstruct.t * int * (string * string) list * (string * Name.t) list
    | `Unikernel_stop of Name.t * int * process_exit
    | `Hup
  ]

  val name : log_event -> Name.t

  val pp_log_event : log_event Fmt.t

  type t = Ptime.t * log_event

  val pp : t Fmt.t
end
