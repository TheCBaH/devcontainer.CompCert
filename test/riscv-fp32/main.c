struct blob { long long alignment; unsigned words[12]; };
extern void axpy(float *, const float *, const float *, int);
extern void dot(float *, const float *, const float *, int);
extern void choose(float *, const float *, int);
extern void rotate(float *, const float *, int);
extern void divide(float *, const float *);
extern void convert32(float *, int *, const int *);
extern void copy_blob(struct blob *, const struct blob *);
extern void copy_volatile(volatile float *, const volatile float *);
extern void pressure(float *, const volatile float *);

static float x[40], y[40], out[40];
static struct blob source, dest;
static union { unsigned bits; float value; } input, output;

int main(void)
{
  static const unsigned patterns[] = {
    0x00000000u, 0x80000000u, 0x00000001u, 0x007fffffu,
    0x00800000u, 0x7f800000u, 0xff800000u, 0x7fc12345u,
    0x7f812345u
  };
  int i, integer = -42, result;
  for (i = 0; i < 40; ++i) { x[i] = (float)i; y[i] = 1.0f; }
  axpy(out, x, y, 40);
  for (i = 0; i < 40; ++i) if (out[i] != (float)(2*i+1)) return 1;
  dot(out, x, y, 40);
  if (out[0] != 780.0f) return 2;
  pressure(out, x);
  if (out[0] != 780.0f) return 3;
  choose(out, x, 1);
  if (out[0] != 0.0f || out[1] != 1.0f) return 4;
  choose(out, x, 0);
  if (out[0] != 1.0f || out[1] != 0.0f) return 5;
  rotate(out, x, 3);
  if (out[0] != 1.0f || out[1] != 0.0f) return 11;
  rotate(out, x, 4);
  if (out[0] != 0.0f || out[1] != 1.0f) return 12;
  y[0] = 9.0f; y[1] = 4.0f;
  divide(out, y);
  if (out[0] != 2.25f) return 13;
  y[0] = 0.0f; y[1] = 0.0f;
  divide(out, y);
  output.value = out[0];
  if (output.bits != 0x7fc00000u) return 14;
  convert32(out, &result, &integer);
  if (*out != -42.0f || result != -21) return 6;
  source.alignment = 0x123456789abcdef0LL;
  for (i = 0; i < 12; ++i) source.words[i] = (unsigned)(i * 17);
  copy_blob(&dest, &source);
  if (dest.alignment != source.alignment) return 7;
  for (i = 0; i < 12; ++i) if (dest.words[i] != source.words[i]) return 8;
  for (i = 0; i < (int)(sizeof patterns / sizeof patterns[0]); ++i) {
    input.bits = patterns[i];
    copy_volatile(&output.value, &input.value);
    if (output.bits != input.bits) return 9;
    x[0] = input.value;
    choose(out, x, 1);
    output.value = out[0];
    if (output.bits != input.bits) return 10;
    rotate(out, x, 2);
    output.value = out[0];
    if (output.bits != input.bits) return 15;
  }
  return 0;
}
