module CI = Cstubs_internals

external _1_Hacl_Bignum_Base_mul_wide_add_u64
  : Unsigned.uint64 -> Unsigned.uint64 -> Unsigned.uint64 -> _ CI.fatptr ->
    Unsigned.uint64 = "_1_Hacl_Bignum_Base_mul_wide_add_u64" 

external _2_Hacl_Bignum_Base_mul_wide_add2_u32
  : Unsigned.uint32 -> Unsigned.uint32 -> Unsigned.uint32 -> _ CI.fatptr ->
    Unsigned.uint32 = "_2_Hacl_Bignum_Base_mul_wide_add2_u32" 

external _3_Hacl_Bignum_Base_mul_wide_add2_u64
  : Unsigned.uint64 -> Unsigned.uint64 -> Unsigned.uint64 -> _ CI.fatptr ->
    Unsigned.uint64 = "_3_Hacl_Bignum_Base_mul_wide_add2_u64" 

type 'a result = 'a
type 'a return = 'a
type 'a fn =
 | Returns  : 'a CI.typ   -> 'a return fn
 | Function : 'a CI.typ * 'b fn  -> ('a -> 'b) fn
let map_result f x = f x
let returning t = Returns t
let (@->) f p = Function (f, p)
let foreign : type a b. string -> (a -> b) fn -> (a -> b) =
  fun name t -> match t, name with
| Function
    (CI.Primitive CI.Uint64_t,
     Function
       (CI.Primitive CI.Uint64_t,
        Function
          (CI.Primitive CI.Uint64_t,
           Function (CI.Pointer _, Returns (CI.Primitive CI.Uint64_t))))),
  "Hacl_Bignum_Base_mul_wide_add2_u64" ->
  (fun x1 x2 x3 x4 ->
    let CI.CPointer x5 = x4 in
    _3_Hacl_Bignum_Base_mul_wide_add2_u64 x1 x2 x3 x5)
| Function
    (CI.Primitive CI.Uint32_t,
     Function
       (CI.Primitive CI.Uint32_t,
        Function
          (CI.Primitive CI.Uint32_t,
           Function (CI.Pointer _, Returns (CI.Primitive CI.Uint32_t))))),
  "Hacl_Bignum_Base_mul_wide_add2_u32" ->
  (fun x6 x7 x8 x9 ->
    let CI.CPointer x10 = x9 in
    _2_Hacl_Bignum_Base_mul_wide_add2_u32 x6 x7 x8 x10)
| Function
    (CI.Primitive CI.Uint64_t,
     Function
       (CI.Primitive CI.Uint64_t,
        Function
          (CI.Primitive CI.Uint64_t,
           Function (CI.Pointer _, Returns (CI.Primitive CI.Uint64_t))))),
  "Hacl_Bignum_Base_mul_wide_add_u64" ->
  (fun x11 x12 x13 x14 ->
    let CI.CPointer x15 = x14 in
    _1_Hacl_Bignum_Base_mul_wide_add_u64 x11 x12 x13 x15)
| _, s ->  Printf.ksprintf failwith "No match for %s" s


let foreign_value : type a. string -> a Ctypes.typ -> a Ctypes.ptr =
  fun name t -> match t, name with
| _, s ->  Printf.ksprintf failwith "No match for %s" s
