#include <stdio.h>
#include <math.h>
#include <caml/mlvalues.h>

#include "f2c.h"

#ifndef __unused
# if __GNUC__ >= 3
#  define __unused __attribute__ ((unused))
# else
#  define __unused
# endif
#endif

extern void zdotc_(
    doublecomplex *RES,
    integer *N,
    doublecomplex *X, integer *OFSX,
    doublecomplex *Y, integer *OFSY);

CAMLprim value lacaml_zdot_is_procedure(value __unused v_unit)
{
  doublecomplex C = { 42, 43 };
  integer *N = (integer *) &C.r;
  double expected;

  *N = 1;
  expected = C.r * C.r + C.i * C.i;

  zdotc_(&C, N, &C, N, &C, N);

  return Val_bool(fabs(expected - C.r) < 1e-15);
}
