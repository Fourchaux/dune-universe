(** This module extends the Base [Blit_intf] module *)

open Base.Blit_intf

module type S_permissions = sig
  open Perms.Export
  type -'perms t
  val blit        : ([> read] t, [>   write] t) blit
  val blito       : ([> read] t, [>   write] t) blito
  val unsafe_blit : ([> read] t, [>   write] t) blit
  val sub         : ([> read] t, [< _ perms] t) sub
  val subo        : ([> read] t, [< _ perms] t) subo
end

module type S1_permissions = sig
  open Perms.Export
  type ('a, -'perms) t
  val blit        : (('a, [> read]) t, ('a, [>   write]) t) blit
  val blito       : (('a, [> read]) t, ('a, [>   write]) t) blito
  val unsafe_blit : (('a, [> read]) t, ('a, [>   write]) t) blit
  val sub         : (('a, [> read]) t, ('a, [< _ perms]) t) sub
  val subo        : (('a, [> read]) t, ('a, [< _ perms]) t) subo
end

module type Blit = sig
  include Base.Blit_intf.Blit (** @open *)

  module type S_permissions  = S_permissions
  module type S1_permissions = S1_permissions
end
