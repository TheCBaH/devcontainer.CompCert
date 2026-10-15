#include "varargs.h"

int main(void) {
  int cc = cc_driver();
  if (cc) return cc;
  int gcc = gcc_driver();
  return gcc ? gcc + 20 : 0;
}
