typedef unsigned int u32;
typedef unsigned long long u64;
typedef long long i64;

extern float __compcert_fp32_truncate(u64);
extern u64 __compcert_fp32_extend(float);

#define BINARY(name, instruction) \
u64 __compcert_fp64_##name(u64 a, u64 b) { \
  float x = __compcert_fp32_truncate(a), y = __compcert_fp32_truncate(b), z; \
  __asm__(instruction " %0,%1,%2,rne" : "=f"(z) : "f"(x), "f"(y)); \
  return __compcert_fp32_extend(z); \
}
BINARY(add, "fadd.s")
BINARY(sub, "fsub.s")
BINARY(mul, "fmul.s")
BINARY(div, "fdiv.s")
#undef BINARY

#define MINMAX(name, instruction) \
u64 __compcert_fp64_##name(u64 a, u64 b) { \
  float x = __compcert_fp32_truncate(a), y = __compcert_fp32_truncate(b), z; \
  __asm__(instruction " %0,%1,%2" : "=f"(z) : "f"(x), "f"(y)); \
  return __compcert_fp32_extend(z); \
}
MINMAX(min, "fmin.s")
MINMAX(max, "fmax.s")
#undef MINMAX

#define COMPARE(name, op) \
int __compcert_fp64_##name(u64 a, u64 b) { \
  float x = __compcert_fp32_truncate(a), y = __compcert_fp32_truncate(b); \
  return x op y; \
}
COMPARE(eq, ==)
COMPARE(ne, !=)
COMPARE(lt, <)
COMPARE(le, <=)
COMPARE(gt, >)
COMPARE(ge, >=)
#undef COMPARE

u64 __compcert_fp64_sqrt(u64 a) {
  float x = __compcert_fp32_truncate(a), z;
  __asm__("fsqrt.s %0,%1,rne" : "=f"(z) : "f"(x));
  return __compcert_fp32_extend(z);
}

#define FUSED(name, instruction) \
u64 __compcert_fp64_##name(u64 a, u64 b, u64 c) { \
  float x = __compcert_fp32_truncate(a), y = __compcert_fp32_truncate(b); \
  float z = __compcert_fp32_truncate(c), r; \
  __asm__(instruction " %0,%1,%2,%3,rne" : "=f"(r) : "f"(x), "f"(y), "f"(z)); \
  return __compcert_fp32_extend(r); \
}
FUSED(fmadd, "fmadd.s")
FUSED(fmsub, "fmsub.s")
FUSED(fnmadd, "fnmadd.s")
FUSED(fnmsub, "fnmsub.s")
#undef FUSED

float __compcert_fp32_from_u64(u64 a) {
  union { u32 u; float f; } v = { .u = 0 };
  if (!a) return v.f;
  unsigned e = 0;
  for (u64 n = a; n >>= 1;) ++e;
  u64 significand;
  if (e <= 23) significand = a << (23 - e);
  else {
    unsigned shift = e - 23;
    significand = a >> shift;
    u64 remainder = a & ((1ULL << shift) - 1);
    u64 halfway = 1ULL << (shift - 1);
    if (remainder > halfway || (remainder == halfway && (significand & 1)))
      ++significand;
    if (significand == (1ULL << 24)) { significand >>= 1; ++e; }
  }
  v.u = ((e + 127) << 23) | ((u32)significand & 0x7fffffu);
  return v.f;
}

float __compcert_fp32_from_i64(i64 a) {
  float x = __compcert_fp32_from_u64(a < 0 ? -(u64)a : (u64)a);
  return a < 0 ? -x : x;
}

u64 __compcert_fp64_from_i32(int a) {
  float x;
  __asm__("fcvt.s.w %0,%1,rne" : "=f"(x) : "r"(a));
  return __compcert_fp32_extend(x);
}
u64 __compcert_fp64_from_u32(u32 a) {
  float x;
  __asm__("fcvt.s.wu %0,%1,rne" : "=f"(x) : "r"(a));
  return __compcert_fp32_extend(x);
}
u64 __compcert_fp64_from_i64(i64 a) {
  return __compcert_fp32_extend(__compcert_fp32_from_i64(a));
}
u64 __compcert_fp64_from_u64(u64 a) {
  return __compcert_fp32_extend(__compcert_fp32_from_u64(a));
}

/* RV32 has no float-to-64-bit integer instruction. Decode the rounded FP32. */
static u64 magnitude(u64 a, int *negative) {
  union { float f; u32 u; } v = { .f = __compcert_fp32_truncate(a) };
  int e = (int)((v.u >> 23) & 255) - 127;
  *negative = (int)(v.u >> 31);
  if (e < 0) return 0;
  if (e > 63) return ~0ULL;
  u64 significand = (v.u & 0x7fffffu) | 0x800000u;
  return e >= 23 ? significand << (e - 23) : significand >> (23 - e);
}

u64 __compcert_fp64_to_u64(u64 a) {
  int negative;
  u64 m = magnitude(a, &negative);
  return negative ? 0 : m;
}

i64 __compcert_fp64_to_i64(u64 a) {
  int negative;
  u64 m = magnitude(a, &negative);
  if (m > 0x7fffffffffffffffULL)
    return negative ? (-0x7fffffffffffffffLL - 1) : 0x7fffffffffffffffLL;
  return negative ? -(i64)m : (i64)m;
}

int __compcert_fp64_to_i32(u64 a) { return (int)__compcert_fp32_truncate(a); }
u32 __compcert_fp64_to_u32(u64 a) { return (u32)__compcert_fp32_truncate(a); }
