typedef unsigned long long u64;
extern void fp64_report(const u64 *data, unsigned size);

int main(void) {
  const unsigned edges32[] = { 0,0x80000000u,1,0x007fffffu,0x00800000u,
    0x7f7fffffu,0xff7fffffu,0x7f800000u,0xff800000u,0x7fc12345u,0x7fa12345u };
  const u64 edges64[] = { 0,0x8000000000000000ULL,1,0x7ff0000000000000ULL,
    0xfff0000000000000ULL,0x7ff8123456789abcULL,0x7ff0123456789abcULL,
    0x3690000000000000ULL,0x3690000000000001ULL,0x368fffffffffffffULL,
    0x36a0000000000000ULL,0x380fffffc0000000ULL,0x3810000000000000ULL,
    0x47efffffe0000000ULL,0x47effffff0000000ULL,0x3ff0000010000000ULL,
    0x3ff0000010000001ULL,0x3ff0000030000000ULL,0xbff0000030000000ULL };
  u64 results[128];
  unsigned seed = 0x12345678u;
  for (unsigned i = 0; i < 30000; ++i) {
    union { float f; unsigned u; } a, out;
    union { double d; u64 u; } b, extended;
    seed = seed * 1664525u + 1013904223u;
    a.u = i < sizeof(edges32)/sizeof(edges32[0]) ? edges32[i] : seed;
    extended.d = a.f;
    results[2 * (i & 63)] = extended.u;
    b.u = (u64)seed << 32;
    seed = seed * 1664525u + 1013904223u;
    b.u |= seed;
    if (i < sizeof(edges64)/sizeof(edges64[0])) b.u = edges64[i];
    out.f = (float)b.d;
    results[2 * (i & 63) + 1] = out.u;
    if ((i & 63) == 63) fp64_report(results, sizeof(results));
  }
  fp64_report(results, (30000u & 63) * 16);
  return 0;
}
