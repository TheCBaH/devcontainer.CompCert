#ifndef COMPCERT_FP32_STDIO_H
#define COMPCERT_FP32_STDIO_H
#include <stdarg.h>
#include <stddef.h>
int printf(const char *, ...);
int vprintf(const char *, va_list);
int snprintf(char *, size_t, const char *, ...);
int vsnprintf(char *, size_t, const char *, va_list);
int putchar(int);
int puts(const char *);
#endif
