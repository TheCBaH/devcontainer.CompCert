struct blob { long long alignment; unsigned words[12]; };

void axpy(float *out, const float *x, const float *y, int n)
{
  int i;
  for (i = 0; i < n; ++i) out[i] = 2.0f * x[i] + y[i];
}

void dot(float *out, const float *x, const float *y, int n)
{
  float sum = 0.0f;
  int i;
  for (i = 0; i < n; ++i) sum += x[i] * y[i];
  *out = sum;
}

void choose(float *out, const float *x, int select)
{
  float a = x[0], b = x[1];
  out[0] = select ? a : b;
  out[1] = select ? b : a;
}

void rotate(float *out, const float *x, int n)
{
  float a = x[0], b = x[1];
  while (n-- > 0) { float t = a; a = b; b = t; }
  out[0] = a;
  out[1] = b;
}

void divide(float *out, const float *x)
{
  *out = x[0] / x[1];
}

void convert32(float *out, int *result, const int *x)
{
  float a = (float)*x;
  *out = a;
  *result = (int)(a * 0.5f);
}

void copy_blob(struct blob *out, const struct blob *in)
{
  *out = *in;
}

void copy_volatile(volatile float *out, const volatile float *in)
{
  *out = *in;
}
