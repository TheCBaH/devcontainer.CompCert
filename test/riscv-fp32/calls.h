#ifndef FP32_CALLS_H
#define FP32_CALLS_H

#define FP32_JOIN_(a, b) a##b
#define FP32_JOIN(a, b) FP32_JOIN_(a, b)
#define FP32_MANY_PARAMS \
  float a01, float a02, float a03, float a04, float a05, float a06, \
  float a07, float a08, float a09, float a10, float a11, float a12, \
  float a13, float a14, float a15, float a16, float a17, float a18
#define FP32_MANY_ARGS \
  1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f, 7.0f, 8.0f, 9.0f, \
  10.0f, 11.0f, 12.0f, 13.0f, 14.0f, 15.0f, 16.0f, 17.0f, 18.0f
#define FP32_NINTH_ARGS(x) \
  1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f, 7.0f, 8.0f, x, \
  10.0f, 11.0f, 12.0f, 13.0f, 14.0f, 15.0f, 16.0f, 17.0f, 18.0f
#define FP32_LAST_ARGS(x) \
  1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f, 7.0f, 8.0f, 9.0f, \
  10.0f, 11.0f, 12.0f, 13.0f, 14.0f, 15.0f, 16.0f, 17.0f, x
#define FP32_MIXED_PARAMS \
  const float *p, int i0, float f0, int i1, float f1, int i2, float f2, \
  int i3, float f3, int i4, float f4, int i5, float f5, int i6, float f6, \
  int i7, float f7, int i8, float f8, int i9, float f9
#define FP32_MIXED_ARGS(p) \
  p, 11, 1.0f, 12, 2.0f, 13, 3.0f, 14, 4.0f, 15, 5.0f, \
  16, 6.0f, 17, 7.0f, 18, 8.0f, 19, 9.0f, 20, 10.0f
#define FP32_DECLARE(prefix) \
  extern float FP32_JOIN(prefix, leaf)(float, float); \
  extern float FP32_JOIN(prefix, identity)(float); \
  extern float FP32_JOIN(prefix, many)(FP32_MANY_PARAMS); \
  extern float FP32_JOIN(prefix, ninth)(FP32_MANY_PARAMS); \
  extern float FP32_JOIN(prefix, last)(FP32_MANY_PARAMS); \
  extern float FP32_JOIN(prefix, mixed)(FP32_MIXED_PARAMS)

FP32_DECLARE(cc_);
FP32_DECLARE(gcc_);
typedef float (*fp32_unary)(float);
extern float cc_chain(float);
extern float cc_tail(float, float);
extern float cc_indirect(fp32_unary, float);
extern float cc_tail_indirect(fp32_unary, float);
extern float cc_overflow(const float *);
extern float cc_recurse(float, int);
extern float cc_roundtrip(float);
extern float cc_payload_ninth(float);
extern float cc_payload_last(float);
extern void cc_live_copy(float *, const volatile float *);
extern void cc_call_pressure(float *, const volatile float *);
extern float gcc_clobber(void);
extern int gcc_stack_alignment(void);
extern int check_saved(void);
#endif
