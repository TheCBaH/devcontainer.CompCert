#define NANOPRINTF_USE_FIELD_WIDTH_FORMAT_SPECIFIERS 1
#define NANOPRINTF_USE_PRECISION_FORMAT_SPECIFIERS 1
#define NANOPRINTF_USE_FLOAT_FORMAT_SPECIFIERS 1
#define NANOPRINTF_USE_LARGE_FORMAT_SPECIFIERS 1
#define NANOPRINTF_USE_SMALL_FORMAT_SPECIFIERS 1
#define NANOPRINTF_USE_BINARY_FORMAT_SPECIFIERS 0
#define NANOPRINTF_USE_WRITEBACK_FORMAT_SPECIFIERS 1
#define NANOPRINTF_USE_ALT_FORM_FLAG 1
#define NANOPRINTF_USE_LONG_DOUBLE_FORMAT_SPECIFIERS 0
#define NANOPRINTF_USE_FLOAT_HEX_FORMAT_SPECIFIER 1
#define NANOPRINTF_USE_FLOAT_SCI_FORMAT_SPECIFIER 1
#define NANOPRINTF_USE_FLOAT_SHORTEST_FORMAT_SPECIFIER 1
#define NANOPRINTF_USE_DIVISION_FREE_CONVERSION 1
#define NANOPRINTF_IMPLEMENTATION
#include "nanoprintf.h"

static long write_stdout(const char *buffer, unsigned long size) {
  register long result __asm__("a0") = 1;
  register const char *data __asm__("a1") = buffer;
  register unsigned long count __asm__("a2") = size;
  register long number __asm__("a7") = 64;
  __asm__ volatile ("ecall" : "+r"(result) : "r"(data), "r"(count), "r"(number) : "memory");
  return result;
}

struct output { char buffer[256]; unsigned used; int failed; };

static void flush(struct output *out) {
  unsigned offset = 0;
  while (offset < out->used && !out->failed) {
    long n = write_stdout(out->buffer + offset, out->used - offset);
    if (n == -4) continue;
    if (n <= 0) out->failed = 1;
    else offset += (unsigned)n;
  }
  out->used = 0;
}

static void emit(int c, void *context) {
  struct output *out = context;
  if (!out->failed) {
    out->buffer[out->used++] = (char)c;
    if (out->used == sizeof(out->buffer)) flush(out);
  }
}

int vprintf(const char *format, va_list ap) {
  struct output out = { .used = 0, .failed = 0 };
  int count = npf_vpprintf(emit, &out, format, ap);
  flush(&out);
  return out.failed ? -1 : count;
}

int printf(const char *format, ...) {
  va_list ap;
  va_start(ap, format);
  int count = vprintf(format, ap);
  va_end(ap);
  return count;
}

int vsnprintf(char *buffer, size_t size, const char *format, va_list ap) {
  return npf_vsnprintf(buffer, size, format, ap);
}

int snprintf(char *buffer, size_t size, const char *format, ...) {
  va_list ap;
  va_start(ap, format);
  int count = vsnprintf(buffer, size, format, ap);
  va_end(ap);
  return count;
}

int puts(const char *s) { return printf("%s\n", s) < 0 ? -1 : 0; }
int putchar(int c) {
  char byte = (char)c;
  return write_stdout(&byte, 1) == 1 ? (unsigned char)byte : -1;
}

void *memcpy(void *dest, const void *src, size_t size) {
  char *d = dest;
  const char *s = src;
  for (size_t i = 0; i < size; ++i) d[i] = s[i];
  return dest;
}
void *memset(void *dest, int value, size_t size) {
  unsigned char *d = dest;
  for (size_t i = 0; i < size; ++i) d[i] = (unsigned char)value;
  return dest;
}
int memcmp(const void *a, const void *b, size_t size) {
  const unsigned char *x = a, *y = b;
  for (size_t i = 0; i < size; ++i) if (x[i] != y[i]) return x[i] - y[i];
  return 0;
}
size_t strlen(const char *s) { size_t n = 0; while (s[n]) ++n; return n; }
int strcmp(const char *a, const char *b) {
  while (*a && *a == *b) { ++a; ++b; }
  return (unsigned char)*a - (unsigned char)*b;
}
