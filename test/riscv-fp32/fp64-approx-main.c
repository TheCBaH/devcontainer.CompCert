typedef unsigned long long u64;
void approx_operations(u64, u64, u64, u64 *);
void approx_integer_input(u64, long long, unsigned, int, u64 *);
void approx_integer_output(u64, u64 *);
void approx_signed_integer_output(u64, u64 *);
void approx_wide_integer_output(u64, u64 *);
int approx_side_effects(void);
void fp64_report(const void *, unsigned long);

static u64 state = 0xd4e12c77a903851fULL;
static u64 random_bits(void) {
  state ^= state << 13; state ^= state >> 7; state ^= state << 17;
  return state;
}
static const u64 edges[] = {
  0, 0x8000000000000000ULL, 1, 0x000fffffffffffffULL,
  0x0010000000000000ULL, 0x7fefffffffffffffULL,
  0x7ff0000000000000ULL, 0xfff0000000000000ULL,
  0x7ff8000000000042ULL, 0x7ff0000000000001ULL, 0xfff8000000000123ULL,
  0x3ff0000000000000ULL, 0x3ff0000000000001ULL,
  0x3ff0000010000000ULL, 0x3ff0000010000001ULL,
  0x47efffffe0000000ULL, 0x47effffff0000000ULL,
  0x3690000000000000ULL, 0x36a0000000000000ULL,
  0x36a0000000000001ULL, 0x3810000000000000ULL,
  0xc000000000000000ULL, 0x3fb999999999999aULL
};
int main(void) {
  int r = approx_side_effects();
  if (r) return r;
  u64 out[16];
  unsigned n = sizeof(edges) / sizeof(edges[0]);
  for (unsigned i = 0; i < n; ++i)
    for (unsigned j = 0; j < n; ++j) {
      approx_operations(edges[i], edges[j], edges[(i + j) % n], out);
      fp64_report(out, sizeof(out));
    }
  for (unsigned i = 0; i < 12000; ++i) {
    u64 a = random_bits(), b = random_bits(), c = random_bits();
    approx_operations(a, b, c, out); fp64_report(out, sizeof(out));
    approx_integer_input(a, (long long)b, (unsigned)c, (int)(c >> 32), out);
    fp64_report(out, 6 * sizeof(u64));
    /* All integer destinations below are in range after FP32 rounding. */
    unsigned value = i % 100, e = 0;
    for (unsigned n = value; n >>= 1;) ++e;
    u64 v = value ? ((u64)(e + 1023) << 52) |
      (((u64)value << (52 - e)) & 0xfffffffffffffULL) : 0;
    approx_integer_output(v, out); fp64_report(out, 6 * sizeof(u64));
    approx_signed_integer_output(v | 0x8000000000000000ULL, out);
    fp64_report(out, 2 * sizeof(u64));
    unsigned wide_e = (unsigned)(c % 63);
    u64 wide = ((u64)(wide_e + 1023) << 52) | ((a & 0x7fffff) << 29);
    approx_wide_integer_output(wide, out); fp64_report(out, 4 * sizeof(u64));
  }
  return 0;
}
