(*  Orpie -- a fullscreen RPN calculator for the console
 *  Copyright (C) 2003-2004, 2005, 2006-2007, 2010, 2018 Paul Pelzl
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License, Version 3,
 *  as published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Please send bug reports, patches, etc. to Paul Pelzl at
 *  <pelzlpj@gmail.com>.
 *)

open Rpc_stack
open Gsl_assist
open Big_int

let mult (stack : rpc_stack) (evaln : int -> unit) =
   evaln 2;
   let gen_el2 = stack#pop () in
   let gen_el1 = stack#pop () in
   match gen_el1 with
   |RpcInt el1 -> (
      match gen_el2 with
      |RpcInt el2 ->
         stack#push (RpcInt (mult_big_int el1 el2))
      |RpcFloatUnit (el2, uu2) ->
         let f_el1 = float_of_big_int el1 in
         stack#push (RpcFloatUnit (f_el1 *. el2, uu2))
      |RpcComplexUnit (el2, uu2) ->
         let c_el1 = {
            Complex.re = float_of_big_int el1;
            Complex.im = 0.0
         } in
         stack#push (RpcComplexUnit (Complex.mul c_el1 el2, uu2))
      |RpcFloatMatrixUnit (el2, uu) ->
         let result = Gsl.Matrix.copy el2 in
         Gsl.Matrix.scale result (float_of_big_int el1);
         stack#push (RpcFloatMatrixUnit (result, uu))
      |RpcComplexMatrixUnit (el2, uu) ->
         let c_el1 = cmpx_of_int el1 in
         let result = Gsl.Matrix_complex.copy el2 in
         Gsl.Matrix_complex.scale result c_el1;
         stack#push (RpcComplexMatrixUnit (result, uu))
      |_ ->
         (stack#push gen_el1;
         stack#push gen_el2;
         raise (Invalid_argument "incompatible types for multiplication"))
      )
   |RpcFloatUnit (el1, uu1) -> (
      match gen_el2 with
      |RpcInt el2 ->
         let f_el2 = float_of_big_int el2 in
         stack#push (RpcFloatUnit (el1 *. f_el2, uu1))
      |RpcFloatUnit (el2, uu2) ->
         stack#push (RpcFloatUnit (el1 *. el2, Units.mult uu1 uu2))
      |RpcComplexUnit (el2, uu2) ->
         let c_el1 = c_of_f el1 in
         stack#push (RpcComplexUnit (Complex.mul c_el1 el2, Units.mult uu1 uu2))
      |RpcFloatMatrixUnit (el2, uu2) ->
         let uprod = Units.mult uu1 uu2 in
         let result = Gsl.Matrix.copy el2 in
         Gsl.Matrix.scale result el1;
         stack#push (RpcFloatMatrixUnit (result, uprod))
      |RpcComplexMatrixUnit (el2, uu2) ->
         let uprod = Units.mult uu1 uu2 in
         let result = Gsl.Matrix_complex.copy el2 in
         Gsl.Matrix_complex.scale result (c_of_f el1);
         stack#push (RpcComplexMatrixUnit (result, uprod))
      |_ ->
         (stack#push gen_el1;
         stack#push gen_el2;
         raise (Invalid_argument "incompatible types for multiplication"))
      )
   |RpcComplexUnit (el1, uu1) -> (
      match gen_el2 with
      |RpcInt el2 ->
         let c_el2 = cmpx_of_int el2 in
         stack#push (RpcComplexUnit (Complex.mul el1 c_el2, uu1))
      |RpcFloatUnit (el2, uu2) ->
         let c_el2 = c_of_f el2 in
         stack#push (RpcComplexUnit (Complex.mul el1 c_el2, Units.mult uu1 uu2))
      |RpcComplexUnit (el2, uu2) ->
         stack#push (RpcComplexUnit (Complex.mul el1 el2, Units.mult uu1 uu2))
      |RpcFloatMatrixUnit (el2, uu2) ->
         let c_el2 = cmat_of_fmat el2 in
         Gsl.Matrix_complex.scale c_el2 el1;
         stack#push (RpcComplexMatrixUnit (c_el2, Units.mult uu1 uu2))
      |RpcComplexMatrixUnit (el2, uu2) ->
         let result = Gsl.Matrix_complex.copy el2 in
         Gsl.Matrix_complex.scale result el1;
         stack#push (RpcComplexMatrixUnit (result, Units.mult uu1 uu2))
      |_ ->
         (stack#push gen_el1;
         stack#push gen_el2;
         raise (Invalid_argument "incompatible types for multiplication"))
      )
   |RpcFloatMatrixUnit (el1, uu1) -> (
      match gen_el2 with
      |RpcInt el2 ->
         let result = Gsl.Matrix.copy el1 in
         Gsl.Matrix.scale result (float_of_big_int el2);
         stack#push (RpcFloatMatrixUnit (result, uu1))
      |RpcFloatUnit (el2, uu2) ->
         let result = Gsl.Matrix.copy el1 in
         Gsl.Matrix.scale result el2;
         stack#push (RpcFloatMatrixUnit (result, Units.mult uu1 uu2))
      |RpcComplexUnit (el2, uu2) ->
         let c_el1 = cmat_of_fmat el1 in
         Gsl.Matrix_complex.scale c_el1 el2;
         stack#push (RpcComplexMatrixUnit (c_el1, Units.mult uu1 uu2))
      |RpcFloatMatrixUnit (el2, uu2) ->
         let n1, m1 = (Gsl.Matrix.dims el1)
         and n2, m2 = (Gsl.Matrix.dims el2) in
         if m1 = n2 then
            let result = Gsl.Matrix.create n1 m2 in
            Gsl.Blas.gemm ~ta:Gsl.Blas.NoTrans ~tb:Gsl.Blas.NoTrans
              ~alpha:1.0 ~a:el1 ~b:el2 ~beta:0.0 ~c:result;
            stack#push (RpcFloatMatrixUnit (result, Units.mult uu1 uu2))
         else
            (stack#push gen_el1;
            stack#push gen_el2;
            raise (Invalid_argument "incompatible matrix dimensions for multiplication"))
      |RpcComplexMatrixUnit (el2, uu2) ->
         let n1, m1 = (Gsl.Matrix.dims el1)
         and n2, m2 = (Gsl.Matrix_complex.dims el2) in
         if m1 = n2 then
            let c_el1 = cmat_of_fmat el1
            and result = Gsl.Matrix_complex.create n1 m2 in
            Gsl.Blas.Complex.gemm ~ta:Gsl.Blas.NoTrans ~tb:Gsl.Blas.NoTrans
              ~alpha:Complex.one ~a:c_el1 ~b:el2 ~beta:Complex.zero ~c:result;
            stack#push (RpcComplexMatrixUnit (result, Units.mult uu1 uu2))
         else
            (stack#push gen_el1; 
            stack#push gen_el2;
            raise (Invalid_argument "incompatible matrix dimensions for multiplication"))
      |_ ->
         (stack#push gen_el1;
         stack#push gen_el2;
         raise (Invalid_argument "incompatible types for multiplication"))
      )
   |RpcComplexMatrixUnit (el1, uu1) -> (
      match gen_el2 with
      |RpcInt el2 ->
         let c_el2 = cmpx_of_int el2 in
         let result = Gsl.Matrix_complex.copy el1 in
         Gsl.Matrix_complex.scale result c_el2;
         stack#push (RpcComplexMatrixUnit (result, uu1))
      |RpcFloatUnit (el2, uu2) ->
         let result = Gsl.Matrix_complex.copy el1 in
         Gsl.Matrix_complex.scale result Complex.one;
         stack#push (RpcComplexMatrixUnit (result, Units.mult uu1 uu2))
      |RpcComplexUnit (el2, uu2) ->
         let result = Gsl.Matrix_complex.copy el1 in
         Gsl.Matrix_complex.scale result Complex.one;
         stack#push (RpcComplexMatrixUnit (result, Units.mult uu1 uu2))
      |RpcFloatMatrixUnit (el2, uu2) ->
         let n1, m1 = (Gsl.Matrix_complex.dims el1)
         and n2, m2 = (Gsl.Matrix.dims el2) in
         if m1 = n2 then
            let c_el2 = cmat_of_fmat el2
            and result = Gsl.Matrix_complex.create n1 m2 in
            Gsl.Blas.Complex.gemm ~ta:Gsl.Blas.NoTrans ~tb:Gsl.Blas.NoTrans
              ~alpha:Complex.one ~a:el1 ~b:c_el2 ~beta:Complex.zero ~c:result;
            stack#push (RpcComplexMatrixUnit (result, Units.mult uu1 uu2))
         else
            (stack#push gen_el1;
            stack#push gen_el2;
            raise (Invalid_argument "incompatible matrix dimensions for multiplication"))
      |RpcComplexMatrixUnit (el2, uu2) ->
         let n1, m1 = (Gsl.Matrix_complex.dims el1)
         and n2, m2 = (Gsl.Matrix_complex.dims el2) in
         if m1 = n2 then
            let result = Gsl.Matrix_complex.create n1 m2 in
            Gsl.Blas.Complex.gemm ~ta:Gsl.Blas.NoTrans ~tb:Gsl.Blas.NoTrans
              ~alpha:Complex.one ~a:el1 ~b:el2 ~beta:Complex.zero ~c:result;
            stack#push (RpcComplexMatrixUnit (result, Units.mult uu1 uu2))
         else
            (stack#push gen_el1;
            stack#push gen_el2;
            raise (Invalid_argument "incompatible matrix dimensions for multiplication"))
      |_ ->
         (stack#push gen_el1;
         stack#push gen_el2;
         raise (Invalid_argument "incompatible types for multiplication"))
      )
   |_ ->
      (stack#push gen_el1;
      stack#push gen_el2;
      raise (Invalid_argument "incompatible types for multiplication"))


(* arch-tag: DO_NOT_CHANGE_5fc03e41-d1d3-40da-8b68-9a85d96148d0 *)
