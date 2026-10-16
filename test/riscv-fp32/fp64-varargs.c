#include "fp64-varargs.h"

double FP64_FN(echo)(double x) { return x; }
double FP64_FN(from_single)(float x) { return x; }
float FP64_FN(to_single)(double x) { return x; }

double FP64_FN(select)(int n, ...) {
  va_list ap;
  va_start(ap, n);
  double x = 0.0;
  for (int i = 0; i < n; ++i) x = va_arg(ap, double);
  va_end(ap);
  return x;
}

float FP64_FN(fp_vsum)(float x, int n, va_list ap) {
  for (int i = 0; i < n; ++i) x += (float)va_arg(ap, double);
  return x;
}

float FP64_FN(fp_sum)(float x, int n, ...) {
  va_list ap, copy;
  va_start(ap, n);
  va_copy(copy, ap);
  float a = cc_fp_vsum(x, n, ap);
  float b = gcc_fp_vsum(x, n, copy);
  va_end(ap);
  va_end(copy);
  return a == b ? a : -999.0f;
}

double FP64_FN(fp_named)(float x, double y, int n, ...) {
  va_list ap;
  va_start(ap, n);
  double z = va_arg(ap, double);
  va_end(ap);
  return x == 2.0f && (float)y == 3.0f && n == 17 ? z : 99.0;
}

double FP64_FN(fp_aligned)(int a, int b, int c, int d, int e, int f, int g, ...) {
  va_list ap;
  va_start(ap, g);
  double x = va_arg(ap, double);
  int n = va_arg(ap, int);
  double y = va_arg(ap, double);
  va_end(ap);
  return a+b+c+d+e+f+g == 28 && (float)x == 3.0f && n == -23 ? y : 99.0;
}

static fp64_u64 bits(double x) {
  union { double d; fp64_u64 u; } v = { .d = x };
  return v.u;
}
static double value(fp64_u64 x) {
  union { double d; fp64_u64 u; } v = { .u = x };
  return v.d;
}

#define FP64_OVERFLOW(x) 0.0,1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0,16.0,(x)
#define FP64_CHECK(prefix) \
  if (bits(FP64_JOIN(prefix, echo)(value(patterns[i]))) != patterns[i]) return 1; \
  if (bits(FP64_JOIN(prefix, select)(18, FP64_OVERFLOW(value(patterns[i])))) != patterns[i]) return 2; \
  if (bits(FP64_JOIN(prefix, fp_named)(2.0f, 3.0, 17, value(patterns[i]))) != patterns[i]) return 3; \
  if (bits(FP64_JOIN(prefix, fp_aligned)(1,2,3,4,5,6,7,3.0,-23,value(patterns[i]))) != patterns[i]) return 4

int FP64_FN(fp64_driver)(void) {
  const fp64_u64 patterns[] = {
    0, 0x8000000000000000ULL, 1, 0x8000000000000001ULL,
    0x7ff0000000000000ULL, 0xfff0000000000000ULL,
    0x7ff8123456789abcULL, 0x7ff0123456789abcULL, 0xfff923456789abcdULL
  };
  for (unsigned i = 0; i < sizeof(patterns)/sizeof(patterns[0]); ++i) {
    FP64_CHECK(cc_);
    FP64_CHECK(gcc_);
  }
  const unsigned singles[] = {
    0, 0x80000000u, 1, 0x80000001u, 0x7f7fffffu,
    0x7f800000u, 0xff800000u, 0x7fc12345u, 0x7fa12345u, 0xffc12345u
  };
  for (unsigned i = 0; i < sizeof(singles)/sizeof(singles[0]); ++i) {
    union { float f; unsigned u; } x = { .u = singles[i] }, y;
    double a = cc_from_single(x.f);
    double b = gcc_from_single(x.f);
    if (bits(a) != bits(b) || bits(cc_select(1, x.f)) != bits(a) ||
        bits(gcc_select(1, x.f)) != bits(a)) return 5;
    unsigned expected = (singles[i] & 0x7fffffffu) > 0x7f800000u ? 0x7fc00000u : singles[i];
    y.f = cc_to_single(b);
    if (y.u != expected) return 6;
    y.f = gcc_to_single(a);
    if (y.u != expected) return 7;
  }
  if (cc_fp_sum(0.5f, 12, 1.0f,2.0f,3.0f,4.0f,5.0f,6.0f,
                        7.0f,8.0f,9.0f,10.0f,11.0f,12.0f) != 78.5f) return 8;
  if (gcc_fp_sum(0.5f, 12, 1.0f,2.0f,3.0f,4.0f,5.0f,6.0f,
                         7.0f,8.0f,9.0f,10.0f,11.0f,12.0f) != 78.5f) return 9;
  return 0;
}
