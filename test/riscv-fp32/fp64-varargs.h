#include <stdarg.h>
typedef unsigned long long fp64_u64;
#define FP64_JOIN_(a, b) a##b
#define FP64_JOIN(a, b) FP64_JOIN_(a, b)
#define FP64_FN(name) FP64_JOIN(FP64_PREFIX, name)
#define FP64_DECLARE(prefix) \
  int FP64_JOIN(prefix, fp64_driver)(void); \
  double FP64_JOIN(prefix, echo)(double); \
  double FP64_JOIN(prefix, from_single)(float); \
  float FP64_JOIN(prefix, to_single)(double); \
  double FP64_JOIN(prefix, select)(int n, ...); \
  float FP64_JOIN(prefix, fp_vsum)(float, int, va_list); \
  float FP64_JOIN(prefix, fp_sum)(float, int, ...); \
  double FP64_JOIN(prefix, fp_named)(float, double, int, ...); \
  double FP64_JOIN(prefix, fp_aligned)(int, int, int, int, int, int, int, ...)
FP64_DECLARE(cc_);
FP64_DECLARE(gcc_);
