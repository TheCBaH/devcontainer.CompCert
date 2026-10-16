static volatile double values[] = { 1.25, -0.0, 3.5 };
static double copied;

static void copy(double *out, const volatile double *in) { *out = *in; }
static int truth(double x) { return x ? 1 : 0; }

int cc_memory_check(void) {
  struct cell { int before; double value; float after; };
  struct cell a = { 17, 1.25, 3.5f }, b;
  union { double d; unsigned long long u; } v;
  copy(&copied, &values[0]);
  if ((float)copied != 1.25f) return 1;
  copy(&copied, &values[1]);
  v.d = copied;
  if (v.u != 0x8000000000000000ULL || truth(copied) || !truth(values[2])) return 2;
  v.u = 0x7ff0123456789abcULL;
  if (!truth(v.d)) return 3;
  values[0] = v.d;
  copy(&copied, &values[0]);
  v.d = copied;
  if (v.u != 0x7ff0123456789abcULL) return 4;
  b = a;
  if (b.before != 17 || (float)b.value != 1.25f || b.after != 3.5f) return 5;
  if (sizeof(double) != 8 || (char *)&b.value - (char *)&b != 8) return 6;
  return 0;
}
