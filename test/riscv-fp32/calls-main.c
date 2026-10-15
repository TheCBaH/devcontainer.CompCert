#include "calls.h"

static float from_bits(unsigned x) {
  union { unsigned u; float f; } v;
  v.u = x;
  return v.f;
}

static unsigned to_bits(float x) {
  union { unsigned u; float f; } v;
  v.f = x;
  return v.u;
}

int main(void) {
  float p = 3.0f;
  if (cc_leaf(1.25f, 2.5f) != 3.75f) return 1;
  if (cc_chain(2.0f) != 5.0f) return 2;
  if (cc_tail(2.0f, 3.0f) != 5.0f) return 3;
  if (cc_indirect(gcc_identity, 2.0f) != 2.25f ||
      cc_indirect(cc_identity, 2.0f) != 2.25f) return 4;
  if (cc_tail_indirect(gcc_identity, 2.0f) != 2.0f ||
      cc_tail_indirect(cc_identity, 2.0f) != 2.0f) return 5;
  if (cc_many(FP32_MANY_ARGS) != 2109.0f ||
      gcc_many(FP32_MANY_ARGS) != 2109.0f) return 6;
  if (cc_mixed(FP32_MIXED_ARGS(&p)) != 58.0f ||
      gcc_mixed(FP32_MIXED_ARGS(&p)) != 58.0f) return 7;
  if (cc_overflow(&p) != 2167.0f) return 8;
  if (cc_recurse(1.0f, 3) != 10.0f) return 9;
  if (check_saved() != 0) return 10;

  const unsigned patterns[] = {
    0x80000000u, 0x00000001u, 0x7fc12345u, 0x7fa12345u,
    0xffc23456u, 0x80000001u, 0x7f800000u, 0xff800000u
  };
  for (unsigned i = 0; i < sizeof(patterns)/sizeof(patterns[0]); ++i) {
    float x = from_bits(patterns[i]);
    if (to_bits(cc_identity(x)) != patterns[i] ||
        to_bits(cc_roundtrip(x)) != patterns[i] ||
        to_bits(cc_tail_indirect(gcc_identity, x)) != patterns[i] ||
        to_bits(cc_ninth(FP32_NINTH_ARGS(x))) != patterns[i] ||
        to_bits(cc_last(FP32_LAST_ARGS(x))) != patterns[i] ||
        to_bits(cc_payload_ninth(x)) != patterns[i] ||
        to_bits(cc_payload_last(x)) != patterns[i]) return 11;
  }
  float in[40], out[5];
  for (int i = 0; i < 4; ++i) in[i] = from_bits(patterns[i]);
  cc_live_copy(out, in);
  for (int i = 0; i < 4; ++i)
    if (to_bits(out[i]) != patterns[i]) return 12;
  if (out[4] != 3.0f) return 13;
  for (int i = 0; i < 40; ++i) in[i] = (float)i;
  cc_call_pressure(out, in);
  if (out[0] != 783.0f) return 14;
  return 0;
}
