typedef unsigned int fp32_u32;
typedef unsigned long long fp32_u64;

fp32_u64 __compcert_fp32_extend(float x) {
  union { float f; fp32_u32 u; } v = { .f = x };
  fp32_u32 exponent = (v.u >> 23) & 255u;
  fp32_u32 fraction = v.u & 0x7fffffu;
  fp32_u64 sign = (fp32_u64)(v.u & 0x80000000u) << 32;
  if (exponent == 255u)
    return fraction ? 0x7ff8000000000000ULL : sign | 0x7ff0000000000000ULL;
  if (!exponent) {
    if (!fraction) return sign;
    int e = -126;
    while (!(fraction & 0x800000u)) { fraction <<= 1; --e; }
    exponent = (fp32_u32)(e + 1023);
    fraction &= 0x7fffffu;
  } else {
    exponent += 896u;
  }
  return sign | ((fp32_u64)exponent << 52) | ((fp32_u64)fraction << 29);
}

float __compcert_fp32_truncate(fp32_u64 x) {
  union { float f; fp32_u32 u; } v;
  fp32_u32 sign = (fp32_u32)(x >> 32) & 0x80000000u;
  fp32_u32 exponent = (fp32_u32)(x >> 52) & 2047u;
  fp32_u64 fraction = x & 0xfffffffffffffULL;
  v.u = sign;
  if (exponent == 2047u) {
    v.u = fraction ? 0x7fc00000u : sign | 0x7f800000u;
  } else if (exponent) {
    int e = (int)exponent - 1023;
    if (e > 127) {
      v.u = sign | 0x7f800000u;
    } else if (e >= -150) {
      fp32_u64 significand = fraction | (1ULL << 52);
      unsigned shift = e >= -126 ? 29u : (unsigned)(-e - 97);
      fp32_u64 rounded = significand >> shift;
      fp32_u64 remainder = significand & ((1ULL << shift) - 1);
      fp32_u64 halfway = 1ULL << (shift - 1);
      if (remainder > halfway || (remainder == halfway && (rounded & 1))) ++rounded;
      if (e < -126) {
        v.u = sign | (fp32_u32)rounded;
      } else {
        if (rounded == (1ULL << 24)) { rounded >>= 1; ++e; }
        v.u = e > 127 ? sign | 0x7f800000u :
          sign | ((fp32_u32)(e + 127) << 23) | ((fp32_u32)rounded & 0x7fffffu);
      }
    }
  }
  return v.f;
}

double __extendsfdf2(float x) {
  union { fp32_u64 u; double d; } v = { .u = __compcert_fp32_extend(x) };
  return v.d;
}

float __truncdfsf2(double x) {
  union { fp32_u64 u; double d; } v = { .d = x };
  return __compcert_fp32_truncate(v.u);
}

void *__compcert_fp32_va_composite(void **ap, unsigned long size,
                                    unsigned long alignment) {
  unsigned long p = (unsigned long)*ap;
  unsigned long word = sizeof(void *);
  if (size > 2 * word) {
    void *result = *(void **)p;
    *ap = (void *)(p + word);
    return result;
  }
  if (alignment < word) alignment = word;
  if (alignment > 16) alignment = 16;
  p = (p + alignment - 1) & -alignment;
  *ap = (void *)(p + ((size + word - 1) & -word));
  return (void *)p;
}
