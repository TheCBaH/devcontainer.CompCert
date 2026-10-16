typedef unsigned int u32;
typedef unsigned long long u64;
typedef long long i64;
#ifdef FP32_REFERENCE
#define R(x) ((double)(float)(x))
#define SINGLE(x) ((float)(x))
#else
#define R(x) (x)
#define SINGLE(x) (x)
#endif

#ifdef FP32_REFERENCE
static double select_value(int c, double a, double b) { return c ? a : b; }
#define SELECT select_value
#else
#define SELECT __builtin_sel
#endif
static int selected_count;
static double counted(double x) { ++selected_count; return x; }

static u64 bits(double d) {
  union { double d; u64 u; } x = { .d = d };
  return x.u;
}

void approx_operations(u64 aa, u64 bb, u64 cc, u64 *out) {
  union { u64 u; double d; } a = { .u = aa }, b = { .u = bb }, c = { .u = cc };
  double x = a.d, y = b.d, z = c.d;
  out[0] = bits(R(SINGLE(x) + SINGLE(y)));
  out[1] = bits(R(SINGLE(x) - SINGLE(y)));
  out[2] = bits(R(SINGLE(x) * SINGLE(y)));
  out[3] = bits(R(SINGLE(x) / SINGLE(y)));
  out[4] = (SINGLE(x) == SINGLE(y)) | ((SINGLE(x) != SINGLE(y)) << 1)
    | ((SINGLE(x) < SINGLE(y)) << 2) | ((SINGLE(x) <= SINGLE(y)) << 3)
    | ((SINGLE(x) > SINGLE(y)) << 4) | ((SINGLE(x) >= SINGLE(y)) << 5);
  out[5] = bits(-x);
  out[6] = bits(__builtin_fabs(x));
#ifdef FP32_REFERENCE
  float sx = (float)x, sy = (float)y, sz = (float)z, r;
  __asm__("fsqrt.s %0,%1,rne" : "=f"(r) : "f"(sx)); out[7] = bits((double)r);
  __asm__("fmin.s %0,%1,%2" : "=f"(r) : "f"(sx), "f"(sy)); out[8] = bits((double)r);
  __asm__("fmax.s %0,%1,%2" : "=f"(r) : "f"(sx), "f"(sy)); out[9] = bits((double)r);
  __asm__("fmadd.s %0,%1,%2,%3,rne" : "=f"(r) : "f"(sx), "f"(sy), "f"(sz)); out[10] = bits((double)r);
  __asm__("fmsub.s %0,%1,%2,%3,rne" : "=f"(r) : "f"(sx), "f"(sy), "f"(sz)); out[11] = bits((double)r);
  __asm__("fnmadd.s %0,%1,%2,%3,rne" : "=f"(r) : "f"(sx), "f"(sy), "f"(sz)); out[12] = bits((double)r);
  __asm__("fnmsub.s %0,%1,%2,%3,rne" : "=f"(r) : "f"(sx), "f"(sy), "f"(sz)); out[13] = bits((double)r);
#else
  out[7] = bits(__builtin_sqrt(x));
  out[8] = bits(__builtin_fmin(x, y));
  out[9] = bits(__builtin_fmax(x, y));
  out[10] = bits(__builtin_fmadd(x, y, z));
  out[11] = bits(__builtin_fmsub(x, y, z));
  out[12] = bits(__builtin_fnmadd(x, y, z));
  out[13] = bits(__builtin_fnmsub(x, y, z));
#endif
  out[14] = bits(R(SINGLE(x) + SINGLE(3)));
  out[15] = bits(R(SINGLE(x) * 0.1f));
}

void approx_integer_input(u64 u, i64 s, u32 ui, int si, u64 *out) {
  out[0] = bits(R(u));
  out[1] = bits(R(s));
  out[2] = bits(R(ui));
  out[3] = bits(R(si));
  union { float f; u32 u; } x;
  x.f = (float)u; out[4] = x.u;
  x.f = (float)s; out[5] = x.u;
}

void approx_integer_output(u64 a, u64 *out) {
  union { u64 u; double d; } x = { .u = a };
  out[0] = (u64)(i64)R(x.d);
  out[1] = (u64)(int)R(x.d);
  out[2] = (u64)R(x.d);
  out[3] = (u32)R(x.d);
  out[4] = (unsigned short)R(x.d);
  out[5] = (signed char)R(x.d);
}

int approx_side_effects(void) {
  volatile double a[3] = { 1.0, 2.0, 3.0 };
  volatile double *p = a;
  double old = (*p++)++;
  if (bits(old) != 0x3ff0000000000000ULL || p != a + 1) return 1;
  if (bits(a[0]) != 0x4000000000000000ULL) return 2;
  *p++ += 0.5;
  if (bits(a[1]) != 0x4004000000000000ULL || p != a + 2) return 3;
  double pre = ++*p;
  if (bits(pre) != 0x4010000000000000ULL) return 4;
  *p -= 1.0; *p *= 2.0; *p /= 3.0;
  if (bits(a[2]) != 0x4000000000000000ULL) return 5;
  struct { signed int x:7; } bf = { 4 };
  bf.x += 1.5;
  if (bf.x != 5) return 6;
  int i = 5;
  i *= 1.5;
  if (i != 7) return 7;
  float f = 1.5f;
  f += 0.5;
  if (f != 2.0f) return 8;
  selected_count = 0;
  double selected = SELECT(0, counted(1.0), counted(2.0));
  if (bits(selected) != 0x4000000000000000ULL || selected_count != 2) return 9;
  union { u64 u; double d; } nan = { .u = 0x7ff0000000000042ULL };
  selected = SELECT(1, nan.d, 0.0);
  if (bits(selected) != nan.u) return 10;
  return 0;
}

void approx_signed_integer_output(u64 a, u64 *out) {
  union { u64 u; double d; } x = { .u = a };
  out[0] = (u64)(i64)R(x.d);
  out[1] = (u64)(int)R(x.d);
}

void approx_wide_integer_output(u64 a, u64 *out) {
  union { u64 u; double d; } x = { .u = a };
  out[0] = (u64)(i64)R(x.d);
  out[1] = (u64)R(x.d);
  out[2] = (u64)(i64)(float)x.d;
  out[3] = (u64)(float)x.d;
}
