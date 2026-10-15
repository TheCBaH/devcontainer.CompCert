#include "calls.h"

float cc_chain(float x) {
  float y = gcc_leaf(x, 1.0f);
  if (gcc_stack_alignment() != 0) return -1.0f;
  return cc_leaf(y, x);
}

float cc_tail(float x, float y) { return gcc_leaf(x, y); }
float cc_indirect(fp32_unary f, float x) { return f(x) + 0.25f; }
float cc_tail_indirect(fp32_unary f, float x) { return f(x); }
float cc_roundtrip(float x) { return gcc_identity(x); }
float cc_payload_ninth(float x) { return gcc_ninth(FP32_NINTH_ARGS(x)); }
float cc_payload_last(float x) { return gcc_last(FP32_LAST_ARGS(x)); }

float cc_overflow(const float *p) {
  float x = gcc_many(FP32_MANY_ARGS);
  float y = gcc_mixed(FP32_MIXED_ARGS(p));
  return x + y;
}

float cc_recurse(float x, int n) {
  if (n == 0) return x;
  float y = gcc_leaf(x, 1.0f);
  return cc_recurse(y, n - 1) + x;
}

void cc_live_copy(float *out, const volatile float *in) {
  float a = in[0], b = in[1], c = in[2], d = in[3];
  float r = gcc_clobber();
  out[0] = a; out[1] = b; out[2] = c; out[3] = d; out[4] = r;
}
