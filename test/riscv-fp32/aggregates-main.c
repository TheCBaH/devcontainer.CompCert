#include "aggregates.h"
#ifndef AGG_DRIVER
#define AGG_DRIVER cc_
#endif
int main(void) { return CAT(AGG_DRIVER,test)(); }
