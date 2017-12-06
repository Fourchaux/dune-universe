
open Bigarray

(* interface to gsl functions, types for interfacing to gsl *)

type ('a, 'b) gsl_vec = ('a, 'b, c_layout) Array1.t
type ('a, 'b) gsl_mat = ('a, 'b, c_layout) Array2.t

type ('a, 'b) gsl_mat_op01 = ('a, 'b) gsl_mat -> ('a, 'b) gsl_mat -> unit
type ('a, 'b) gsl_mat_op02 = ('a, 'b) gsl_mat -> int -> int -> unit
type ('a, 'b) gsl_mat_op03 = ('a, 'b) gsl_mat -> 'a -> ('a, 'b) gsl_mat
type ('a, 'b) gsl_mat_op04 = ('a, 'b) gsl_mat -> unit
type ('a, 'b) gsl_mat_op08 = ('a, 'b) gsl_mat -> ('a, 'b) gsl_mat -> ('a, 'b) gsl_mat
type ('a, 'b) gsl_mat_op09 = 'a array array -> ('a, 'b) gsl_mat
type ('a, 'b) gsl_mat_op10 = ('a, 'b) gsl_mat -> 'a array array
type ('a, 'b) gsl_mat_op11 = 'a array -> int -> int -> ('a, 'b) gsl_mat
type ('a, 'b) gsl_mat_op12 = ('a, 'b) gsl_mat -> 'a array
type ('a, 'b) gsl_vec_op00 = ('a, 'b) gsl_vec -> unit


(* call functions in gsl *)

let transpose_copy : type a b. (a, b) kind -> (a, b) gsl_mat_op01 =
  fun k dst src -> match k with
  | Float32   -> Gsl.Matrix.Single.transpose dst src
  | Float64   -> Gsl.Matrix.transpose dst src
  | Complex32 -> Gsl.Matrix_complex.Single.transpose dst src
  | Complex64 -> Gsl.Matrix_complex.transpose dst src
  | _         -> failwith "transpose_copy: unsupported operation"

let transpose_in_place : type a b. (a, b) kind -> (a, b) gsl_mat_op04 = function
  | Float32   -> Gsl.Matrix.Single.transpose_in_place
  | Float64   -> Gsl.Matrix.transpose_in_place
  | Complex32 -> Gsl.Matrix_complex.Single.transpose_in_place
  | Complex64 -> Gsl.Matrix_complex.transpose_in_place
  | _         -> failwith "transpose_in_place: unsupported operation"

let swap_rows : type a b. (a, b) kind -> (a, b) gsl_mat_op02 = function
  | Float32   -> Gsl.Matrix.Single.swap_rows
  | Float64   -> Gsl.Matrix.swap_rows
  | Complex32 -> Gsl.Matrix_complex.Single.swap_rows
  | Complex64 -> Gsl.Matrix_complex.swap_rows
  | _         -> failwith "swap_rows: unsupported operation"

let swap_cols : type a b. (a, b) kind -> (a, b) gsl_mat_op02 = function
  | Float32   -> Gsl.Matrix.Single.swap_columns
  | Float64   -> Gsl.Matrix.swap_columns
  | Complex32 -> Gsl.Matrix_complex.Single.swap_columns
  | Complex64 -> Gsl.Matrix_complex.swap_columns
  | _         -> failwith "swap_cols: unsupported operation"

let of_arrays : type a b. (a, b) kind -> (a, b) gsl_mat_op09 = function
  | Float32   -> Gsl.Matrix.Single.of_arrays
  | Float64   -> Gsl.Matrix.of_arrays
  | Complex32 -> Gsl.Matrix_complex.Single.of_arrays
  | Complex64 -> Gsl.Matrix_complex.of_arrays
  | _         -> failwith "of_arrays: unsupported operation"

let to_arrays : type a b. (a, b) kind -> (a, b) gsl_mat_op10 = function
  | Float32   -> Gsl.Matrix.Single.to_arrays
  | Float64   -> Gsl.Matrix.to_arrays
  | Complex32 -> Gsl.Matrix_complex.Single.to_arrays
  | Complex64 -> Gsl.Matrix_complex.to_arrays
  | _         -> failwith "to_arrays: unsupported operation"

let of_array : type a b. (a, b) kind -> (a, b) gsl_mat_op11 = function
  | Float32   -> Gsl.Matrix.Single.of_array
  | Float64   -> Gsl.Matrix.of_array
  | Complex32 -> Gsl.Matrix_complex.Single.of_array
  | Complex64 -> Gsl.Matrix_complex.of_array
  | _         -> failwith "of_array: unsupported operation"

let to_array : type a b. (a, b) kind -> (a, b) gsl_mat_op12 = function
  | Float32   -> Gsl.Matrix.Single.to_array
  | Float64   -> Gsl.Matrix.to_array
  | Complex32 -> Gsl.Matrix_complex.Single.to_array
  | Complex64 -> Gsl.Matrix_complex.to_array
  | _         -> failwith "to_array: unsupported operation"

let min : type a b. (a, b) kind -> (a, b) gsl_vec -> a =
  fun k x -> match k with
  | Float32   -> Gsl.Vector.Single.min x
  | Float64   -> Gsl.Vector.min x
  | _         -> failwith "min: unsupported operation"

let max : type a b. (a, b) kind -> (a, b) gsl_vec -> a =
  fun k x -> match k with
  | Float32   -> Gsl.Vector.Single.max x
  | Float64   -> Gsl.Vector.max x
  | _         -> failwith "max: unsupported operation"

let minmax : type a b. (a, b) kind -> (a, b) gsl_vec -> a * a =
  fun k x -> match k with
  | Float32   -> Gsl.Vector.Single.minmax x
  | Float64   -> Gsl.Vector.minmax x
  | _         -> failwith "minmax: unsupported operation"

let min_i : type a b. (a, b) kind -> (a, b) gsl_vec -> int =
  fun k x -> match k with
  | Float32   -> Gsl.Vector.Single.min_index x
  | Float64   -> Gsl.Vector.min_index x
  | _         -> failwith "min_index: unsupported operation"

let max_i : type a b. (a, b) kind -> (a, b) gsl_vec -> int =
  fun k x -> match k with
  | Float32   -> Gsl.Vector.Single.max_index x
  | Float64   -> Gsl.Vector.max_index x
  | _         -> failwith "max_index: unsupported operation"

let minmax_i : type a b. (a, b) kind -> (a, b) gsl_vec -> int * int =
  fun k x -> match k with
  | Float32   -> Gsl.Vector.Single.minmax_index x
  | Float64   -> Gsl.Vector.minmax_index x
  | _         -> failwith "minmax_index: unsupported operation"

let dot : type a b. (a, b) kind -> (a, b) gsl_mat_op08 =
  fun k x1 x2 -> match k with
  | Float32   -> let open Gsl.Blas.Single in
    let m, n = Array2.dim1 x1, Array2.dim2 x2 in
    let x3 = Array2.create (Array2.kind x1) c_layout m n in
    gemm ~ta:Gsl.Blas.NoTrans ~tb:Gsl.Blas.NoTrans ~alpha:1. ~beta:0. ~a:x1 ~b:x2 ~c:x3;
    x3
  | Float64   -> let open Gsl.Blas in
    let m, n = Array2.dim1 x1, Array2.dim2 x2 in
    let x3 = Array2.create (Array2.kind x1) c_layout m n in
    gemm ~ta:Gsl.Blas.NoTrans ~tb:Gsl.Blas.NoTrans ~alpha:1. ~beta:0. ~a:x1 ~b:x2 ~c:x3;
    x3
  | Complex32 -> let open Gsl.Blas.Complex_Single in
    let m, n = Array2.dim1 x1, Array2.dim2 x2 in
    let x3 = Array2.create (Array2.kind x1) c_layout m n in
    gemm ~ta:Gsl.Blas.NoTrans ~tb:Gsl.Blas.NoTrans ~alpha:Complex.one ~beta:Complex.zero ~a:x1 ~b:x2 ~c:x3;
    x3
  | Complex64 -> let open Gsl.Blas.Complex in
    let m, n = Array2.dim1 x1, Array2.dim2 x2 in
    let x3 = Array2.create (Array2.kind x1) c_layout m n in
    gemm ~ta:Gsl.Blas.NoTrans ~tb:Gsl.Blas.NoTrans ~alpha:Complex.one ~beta:Complex.zero ~a:x1 ~b:x2 ~c:x3;
    x3
  | _         -> failwith "dot: unsupported operation"

let add : type a b. (a, b) kind -> (a, b) gsl_mat_op08 =
  fun k x1 x2 -> match k with
  | Float32   -> Gsl.Matrix.Single.add x1 x2; x1
  | Float64   -> Gsl.Matrix.add x1 x2; x1
  | Complex32 -> Gsl.Matrix_complex.Single.add x1 x2; x1
  | Complex64 -> Gsl.Matrix_complex.add x1 x2; x1
  | _         -> failwith "add: unsupported operation"

let sub : type a b. (a, b) kind -> (a, b) gsl_mat_op08 =
  fun k x1 x2 -> match k with
  | Float32   -> Gsl.Matrix.Single.sub x1 x2; x1
  | Float64   -> Gsl.Matrix.sub x1 x2; x1
  | Complex32 -> Gsl.Matrix_complex.Single.sub x1 x2; x1
  | Complex64 -> Gsl.Matrix_complex.sub x1 x2; x1
  | _         -> failwith "sub: unsupported operation"

let mul : type a b. (a, b) kind -> (a, b) gsl_mat_op08 =
  fun k x1 x2 -> match k with
  | Float32   -> Gsl.Matrix.Single.mul_elements x1 x2; x1
  | Float64   -> Gsl.Matrix.mul_elements x1 x2; x1
  | Complex32 -> Gsl.Matrix_complex.Single.mul_elements x1 x2; x1
  | Complex64 -> Gsl.Matrix_complex.mul_elements x1 x2; x1
  | _         -> failwith "mul: unsupported operation"

let div : type a b. (a, b) kind -> (a, b) gsl_mat_op08 =
  fun k x1 x2 -> match k with
  | Float32   -> Gsl.Matrix.Single.div_elements x1 x2; x1
  | Float64   -> Gsl.Matrix.div_elements x1 x2; x1
  | Complex32 -> Gsl.Matrix_complex.Single.div_elements x1 x2; x1
  | Complex64 -> Gsl.Matrix_complex.div_elements x1 x2; x1
  | _         -> failwith "div: unsupported operation"

let add_scalar : type a b. (a, b) kind -> (a, b) gsl_mat_op03 =
  fun k x a -> match k with
  | Float32   -> Gsl.Matrix.Single.add_constant x a; x
  | Float64   -> Gsl.Matrix.add_constant x a; x
  | Complex32 -> Gsl.Matrix_complex.Single.add_constant x a; x
  | Complex64 -> Gsl.Matrix_complex.add_constant x a; x
  | _         -> failwith "add_scalar: unsupported operation"

let mul_scalar : type a b. (a, b) kind -> (a, b) gsl_mat_op03 =
  fun k x a -> match k with
  | Float32   -> Gsl.Matrix.Single.scale x a; x
  | Float64   -> Gsl.Matrix.scale x a; x
  | Complex32 -> Gsl.Matrix_complex.Single.scale x a; x
  | Complex64 -> Gsl.Matrix_complex.scale x a; x
  | _         -> failwith "mul_scalar: unsupported operation"

let reverse : type a b. (a, b) kind -> (a, b) gsl_vec_op00 =
  fun k x -> match k with
  | Float32   -> Gsl.Vector.Single.reverse x
  | Float64   -> Gsl.Vector.reverse x
  | Complex32 -> Gsl.Vector_complex.Single.reverse x
  | Complex64 -> Gsl.Vector_complex.reverse x
  | _         -> failwith "reverse: unsupported operation"
