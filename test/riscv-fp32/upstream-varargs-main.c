#include <stdarg.h>

extern int upstream_main(void);
static int calls, failed;

int printf(const char *format, ...) {
  va_list ap;
  va_start(ap, format);
  int value = va_arg(ap, int);
  va_end(ap);
#if defined(TEST_varargs1)
  const char *expected = "Sum is %d\n";
  if (value != 55 || calls != 0) failed = 1;
#else
  char expected[] = "a = %d\n";
  expected[0] += calls;
  if (value != 42 + calls || calls >= 17) failed = 1;
#endif
  for (int i = 0; ; ++i) {
    if (format[i] != expected[i]) { failed = 1; break; }
    if (!format[i]) break;
  }
  ++calls;
  return 0;
}

int main(void) {
  if (upstream_main() != 0) return 1;
#if defined(TEST_varargs1)
  return failed || calls != 1;
#else
  return failed || calls != 17;
#endif
}
