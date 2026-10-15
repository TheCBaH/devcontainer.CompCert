#include <stdio.h>
#include <stdarg.h>

static int equal(const char *a, const char *b) {
  while (*a && *a == *b) { ++a; ++b; }
  return *a == *b;
}

static int forwarded(const char *format, ...) {
  va_list ap, copy;
  va_start(ap, format);
  va_copy(copy, ap);
  char buffer[128];
  int expected = vsnprintf(buffer, sizeof(buffer), format, copy);
  va_end(copy);
  int actual = vprintf(format, ap);
  va_end(ap);
  return actual == expected;
}

int main(void) {
  volatile float input = 1.25f;
  float x = input;
  char buffer[128], small[5];
  int written = -1;
  int count = snprintf(buffer, sizeof(buffer), "%s %d %u %#x %lld %.3f%n",
    "ok", -17, 4294967295u, 42u, -1234567890123LL, x, &written);
  if (!equal(buffer, "ok -17 4294967295 0x2a -1234567890123 1.250") || count != written) return 1;
  puts(buffer);
  if (snprintf(small, sizeof(small), "abcdef%d", 12) != 8 || !equal(small, "abcd")) return 2;
  if (snprintf(0, 0, "%d %.2f", 17, x) != 7) return 3;
  if (!forwarded("mixed: %d %.2f %llu %.3f\n", -17, x, 18446744073709551615ULL, -2.5f)) return 4;
  printf("formats: %.6a %.6e %.6g %.3f\n", 2.5f, 0.125f, 12345.0f, -0.0f);
  printf("limits: %lld %#llx\n", -9223372036854775807LL - 1, 0xfedcba9876543210ULL);
  return 0;
}
