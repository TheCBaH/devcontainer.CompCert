#include "varargs.h"

int VARARGS_FN(vsum)(int n, va_list ap) {
  int sum = 0;
  for (int i = 0; i < n; ++i) sum += va_arg(ap, int);
  return sum;
}

int VARARGS_FN(sum)(int n, ...) {
  va_list ap, copy;
  va_start(ap, n);
  va_copy(copy, ap);
  int a = VARARGS_FN(vsum)(n, ap);
  int b = VARARGS_FN(vsum)(n, copy);
  va_end(copy);
  va_end(ap);
  return a == b ? a : -999;
}

int VARARGS_FN(forward)(int n, ...) {
  va_list ap;
  va_start(ap, n);
  int a = cc_vsum(n, ap);
  va_end(ap);
  va_start(ap, n);
  int b = gcc_vsum(n, ap);
  va_end(ap);
  return a == b ? a : -999;
}

float VARARGS_FN(named)(float x, int n, ...) {
  va_list ap;
  va_start(ap, n);
  for (int i = 0; i < n; ++i) x += (float)va_arg(ap, int);
  va_end(ap);
  return x;
}

varargs_u64 VARARGS_FN(wide)(int n, ...) {
  va_list ap;
  va_start(ap, n);
  unsigned a = va_arg(ap, unsigned);
  varargs_u64 b = va_arg(ap, varargs_u64);
  int *p = va_arg(ap, int *);
  int c = va_arg(ap, int);
  varargs_u64 d = va_arg(ap, varargs_u64);
  unsigned e = va_arg(ap, unsigned);
  va_end(ap);
  return a == 0xfedcba98u && b == 0x123456789abcdef0ULL &&
         p && *p == 42 && c == -17 && e == 0x87654321u ? d : 0;
}

varargs_u64 VARARGS_FN(aligned)(int a, int b, int c, int d, int e, int f, int g, ...) {
  va_list ap;
  va_start(ap, g);
  varargs_u64 x = va_arg(ap, varargs_u64);
  int y = va_arg(ap, int);
  varargs_u64 z = va_arg(ap, varargs_u64);
  va_end(ap);
  return a+b+c+d+e+f+g == 28 && x == 0xfedcba9876543210ULL && y == -23 ? z : 0;
}

int VARARGS_FN(overflow)(float f0, float f1, float f2, float f3, float f4,
                        float f5, float f6, float f7, float f8,
                        int a0, int a1, int a2, int a3, int a4,
                        int a5, int a6, int a7, int a8, ...) {
  va_list ap;
  va_start(ap, a8);
  int *p = va_arg(ap, int *);
  varargs_u64 x = va_arg(ap, varargs_u64);
  int y = va_arg(ap, int);
  va_end(ap);
  return f0+f1+f2+f3+f4+f5+f6+f7+f8 == 45.0f &&
         a0+a1+a2+a3+a4+a5+a6+a7+a8 == 45 && p && *p == 42 &&
         x == 0x123456789abcdef0ULL && y == -23;
}

#define VARARGS_CHECK(prefix) \
  if (VARARGS_JOIN(prefix, sum)(12, 1,2,3,4,5,6,7,8,9,10,11,12) != 78) return 1; \
  if (VARARGS_JOIN(prefix, sum)(0) != 0) return 2; \
  if (VARARGS_JOIN(prefix, sum)(4, (signed char)-7, (unsigned char)251, \
                               (short)-1000, (unsigned short)65000) != 64244) return 3; \
  if (VARARGS_JOIN(prefix, forward)(12, 1,2,3,4,5,6,7,8,9,10,11,12) != 78) return 4; \
  if (VARARGS_JOIN(prefix, named)(0.5f, 12, 1,2,3,4,5,6,7,8,9,10,11,12) != 78.5f) return 5; \
  if (VARARGS_JOIN(prefix, wide)(0, 0xfedcba98u, 0x123456789abcdef0ULL, &p, \
                                -17, 0xfedcba9876543210ULL, 0x87654321u) != 0xfedcba9876543210ULL) return 6; \
  if (VARARGS_JOIN(prefix, aligned)(1,2,3,4,5,6,7, 0xfedcba9876543210ULL, -23, \
                                    0x123456789abcdef0ULL) != 0x123456789abcdef0ULL) return 7; \
  if (!VARARGS_JOIN(prefix, overflow)(1.0f,2.0f,3.0f,4.0f,5.0f,6.0f,7.0f,8.0f,9.0f, \
                                      1,2,3,4,5,6,7,8,9, &p, 0x123456789abcdef0ULL, -23)) return 8

static int indirect(int (*fn)(int, ...)) {
  return fn(10, 1,2,3,4,5,6,7,8,9,10);
}

static int tail(int n) { return gcc_sum(n, 1,2,3,4); }

int VARARGS_FN(driver)(void) {
  int p = 42;
  VARARGS_CHECK(cc_);
  VARARGS_CHECK(gcc_);
  if (indirect(cc_sum) != 55 || indirect(gcc_sum) != 55) return 9;
  if (tail(4) != 10) return 10;
  return 0;
}
