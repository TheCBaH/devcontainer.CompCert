#include <stdio.h>

struct pair { float x, y; };
volatile float operands[2] = { 1.25f, 2.5f };
volatile unsigned long long numerator = 0xfedcba9876543210ULL;
volatile unsigned long long denominator = 1234567;

struct pair compute(struct pair x) {
  struct pair result = { x.x + x.y, x.x * x.y };
  return result;
}

int main(void) {
  struct pair x = { operands[0], operands[1] };
  struct pair (*volatile fn)(struct pair) = compute;
  struct pair y = fn(x);
  printf("sum=%.2f product=%.3f quotient=%llu remainder=%llu\n",
         y.x, y.y, numerator / denominator, numerator % denominator);
  return y.x != 3.75f || y.y != 3.125f;
}
