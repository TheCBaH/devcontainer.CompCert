#include <stdarg.h>

typedef unsigned long long varargs_u64;

#define VARARGS_JOIN_(a, b) a##b
#define VARARGS_JOIN(a, b) VARARGS_JOIN_(a, b)
#define VARARGS_FN(name) VARARGS_JOIN(VARARGS_PREFIX, name)

#define VARARGS_DECLARE(prefix) \
  int VARARGS_JOIN(prefix, driver)(void); \
  int VARARGS_JOIN(prefix, sum)(int n, ...); \
  int VARARGS_JOIN(prefix, vsum)(int n, va_list ap); \
  int VARARGS_JOIN(prefix, forward)(int n, ...); \
  float VARARGS_JOIN(prefix, named)(float x, int n, ...); \
  varargs_u64 VARARGS_JOIN(prefix, wide)(int n, ...); \
  varargs_u64 VARARGS_JOIN(prefix, aligned)(int, int, int, int, int, int, int, ...); \
  int VARARGS_JOIN(prefix, overflow)(float, float, float, float, float, float, float, float, float, \
                                   int, int, int, int, int, int, int, int, int, ...)

VARARGS_DECLARE(cc_);
VARARGS_DECLARE(gcc_);
