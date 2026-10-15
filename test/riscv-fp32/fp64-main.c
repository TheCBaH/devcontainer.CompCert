#include "fp64-varargs.h"
extern int cc_memory_check(void);
int main(void) {
  int cc = cc_fp64_driver();
  if (cc) return cc;
  int gcc = gcc_fp64_driver();
  if (gcc) return gcc + 20;
  int memory = cc_memory_check();
  return memory ? memory + 40 : 0;
}
