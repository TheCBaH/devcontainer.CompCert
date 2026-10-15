#include "calls.h"
#define FN(name) FP32_JOIN(FP32_PREFIX, name)

float FN(leaf)(float x, float y) { return x + y; }
float FN(identity)(float x) { return x; }
float FN(ninth)(FP32_MANY_PARAMS) { return a09; }
float FN(last)(FP32_MANY_PARAMS) { return a18; }

float FN(many)(FP32_MANY_PARAMS) {
  return a01 + 2.0f*a02 + 3.0f*a03 + 4.0f*a04 + 5.0f*a05 + 6.0f*a06 +
    7.0f*a07 + 8.0f*a08 + 9.0f*a09 + 10.0f*a10 + 11.0f*a11 + 12.0f*a12 +
    13.0f*a13 + 14.0f*a14 + 15.0f*a15 + 16.0f*a16 + 17.0f*a17 + 18.0f*a18;
}

float FN(mixed)(FP32_MIXED_PARAMS) {
  if (i0 != 11 || i1 != 12 || i2 != 13 || i3 != 14 || i4 != 15 ||
      i5 != 16 || i6 != 17 || i7 != 18 || i8 != 19 || i9 != 20 ||
      f0 != 1.0f || f1 != 2.0f || f2 != 3.0f || f3 != 4.0f || f4 != 5.0f ||
      f5 != 6.0f || f6 != 7.0f || f7 != 8.0f || f8 != 9.0f || f9 != 10.0f)
    return -1.0f;
  return *p + 55.0f;
}
