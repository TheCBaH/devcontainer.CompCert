#include "aggregates.h"
#include <stdarg.h>
#include <stddef.h>
#ifndef AGG_PREFIX
#define AGG_PREFIX cc_
#define AGG_OTHER gcc_
#endif
#define FN(n) CAT(AGG_PREFIX,n)
#define OTHER(n) CAT(AGG_OTHER,n)
static void fill(void *p, unsigned n) { unsigned char *b=p; unsigned i; for(i=0;i<n;++i) b[i]=(unsigned char)(17+i*7); }
static int eq(const void *a,const void *b,unsigned n) { const unsigned char *x=a,*y=b; unsigned i; for(i=0;i<n;++i) if(x[i]!=y[i]) return 0; return 1; }
static int same_B1(B1 a,B1 b) { return eq(&a,&b,sizeof(B1)); }
B1 FN(echo_B1)(B1 x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
B1 FN(p7_B1)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, B1 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
B1 FN(p8_B1)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, B1 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_B2(B2 a,B2 b) { return eq(&a,&b,sizeof(B2)); }
B2 FN(echo_B2)(B2 x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
B2 FN(p7_B2)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, B2 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
B2 FN(p8_B2)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, B2 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_B3(B3 a,B3 b) { return eq(&a,&b,sizeof(B3)); }
B3 FN(echo_B3)(B3 x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
B3 FN(p7_B3)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, B3 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
B3 FN(p8_B3)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, B3 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_B4(B4 a,B4 b) { return eq(&a,&b,sizeof(B4)); }
B4 FN(echo_B4)(B4 x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
B4 FN(p7_B4)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, B4 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
B4 FN(p8_B4)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, B4 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_B5(B5 a,B5 b) { return eq(&a,&b,sizeof(B5)); }
B5 FN(echo_B5)(B5 x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
B5 FN(p7_B5)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, B5 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
B5 FN(p8_B5)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, B5 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_B7(B7 a,B7 b) { return eq(&a,&b,sizeof(B7)); }
B7 FN(echo_B7)(B7 x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
B7 FN(p7_B7)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, B7 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
B7 FN(p8_B7)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, B7 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_B8(B8 a,B8 b) { return eq(&a,&b,sizeof(B8)); }
B8 FN(echo_B8)(B8 x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
B8 FN(p7_B8)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, B8 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
B8 FN(p8_B8)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, B8 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_B9(B9 a,B9 b) { return eq(&a,&b,sizeof(B9)); }
B9 FN(echo_B9)(B9 x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
B9 FN(p7_B9)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, B9 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
B9 FN(p8_B9)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, B9 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_B12(B12 a,B12 b) { return eq(&a,&b,sizeof(B12)); }
B12 FN(echo_B12)(B12 x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
B12 FN(p7_B12)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, B12 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
B12 FN(p8_B12)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, B12 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_B15(B15 a,B15 b) { return eq(&a,&b,sizeof(B15)); }
B15 FN(echo_B15)(B15 x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
B15 FN(p7_B15)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, B15 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
B15 FN(p8_B15)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, B15 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_B16(B16 a,B16 b) { return eq(&a,&b,sizeof(B16)); }
B16 FN(echo_B16)(B16 x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
B16 FN(p7_B16)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, B16 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
B16 FN(p8_B16)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, B16 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_B17(B17 a,B17 b) { return eq(&a,&b,sizeof(B17)); }
B17 FN(echo_B17)(B17 x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
B17 FN(p7_B17)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, B17 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
B17 FN(p8_B17)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, B17 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_B24(B24 a,B24 b) { return eq(&a,&b,sizeof(B24)); }
B24 FN(echo_B24)(B24 x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
B24 FN(p7_B24)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, B24 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
B24 FN(p8_B24)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, B24 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_B80(B80 a,B80 b) { return eq(&a,&b,sizeof(B80)); }
B80 FN(echo_B80)(B80 x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
B80 FN(p7_B80)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, B80 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
B80 FN(p8_B80)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, B80 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_B4096(B4096 a,B4096 b) { return eq(&a,&b,sizeof(B4096)); }
B4096 FN(echo_B4096)(B4096 x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
B4096 FN(p7_B4096)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, B4096 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
B4096 FN(p8_B4096)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, B4096 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_F1(F1 a,F1 b) { return eq(&a,&b,sizeof(F1)); }
F1 FN(echo_F1)(F1 x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
F1 FN(p7_F1)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, F1 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
F1 FN(p8_F1)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, F1 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_F2(F2 a,F2 b) { return eq(&a,&b,sizeof(F2)); }
F2 FN(echo_F2)(F2 x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
F2 FN(p7_F2)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, F2 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
F2 FN(p8_F2)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, F2 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_Nested(Nested a,Nested b) { return eq(&a.a,&b.a,sizeof(a.a)); }
Nested FN(echo_Nested)(Nested x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
Nested FN(p7_Nested)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, Nested x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
Nested FN(p8_Nested)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, Nested x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_FI(FI a,FI b) { return eq(&a.x,&b.x,sizeof(a.x)) && eq(&a.i,&b.i,sizeof(a.i)); }
FI FN(echo_FI)(FI x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
FI FN(p7_FI)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, FI x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
FI FN(p8_FI)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, FI x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_IF(IF a,IF b) { return eq(&a.i,&b.i,sizeof(a.i)) && eq(&a.x,&b.x,sizeof(a.x)); }
IF FN(echo_IF)(IF x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
IF FN(p7_IF)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, IF x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
IF FN(p8_IF)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, IF x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_FP(FP a,FP b) { return eq(&a.x,&b.x,sizeof(a.x)) && eq(&a.p,&b.p,sizeof(a.p)); }
FP FN(echo_FP)(FP x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
FP FN(p7_FP)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, FP x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
FP FN(p8_FP)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, FP x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_Packed(Packed a,Packed b) { return eq(&a.c,&b.c,sizeof(a.c)) && eq(&a.x,&b.x,sizeof(a.x)); }
Packed FN(echo_Packed)(Packed x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
Packed FN(p7_Packed)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, Packed x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
Packed FN(p8_Packed)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, Packed x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_Aligned(Aligned a,Aligned b) { return eq(&a.x,&b.x,sizeof(a.x)); }
Aligned FN(echo_Aligned)(Aligned x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
Aligned FN(p7_Aligned)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, Aligned x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
Aligned FN(p8_Aligned)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, Aligned x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_U(U a,U b) { return eq(&a,&b,sizeof(U)); }
U FN(echo_U)(U x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
U FN(p7_U)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, U x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
U FN(p8_U)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, U x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_Bits(Bits a,Bits b) { return a.a==b.a && a.b==b.b && a.c==b.c; }
Bits FN(echo_Bits)(Bits x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
Bits FN(p7_Bits)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, Bits x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
Bits FN(p8_Bits)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, Bits x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_D(D a,D b) { return eq(&a,&b,sizeof(D)); }
D FN(echo_D)(D x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
D FN(p7_D)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, D x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
D FN(p8_D)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, D x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_A8(A8 a,A8 b) { return eq(&a,&b,sizeof(A8)); }
A8 FN(echo_A8)(A8 x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
A8 FN(p7_A8)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, A8 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
A8 FN(p8_A8)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, A8 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_A16(A16 a,A16 b) { return eq(&a,&b,sizeof(A16)); }
A16 FN(echo_A16)(A16 x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
A16 FN(p7_A16)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, A16 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
A16 FN(p8_A16)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, A16 x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_Empty(Empty a,Empty b) { return 1; }
Empty FN(echo_Empty)(Empty x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
Empty FN(p7_Empty)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, Empty x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
Empty FN(p8_Empty)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, Empty x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_BF(BF a,BF b) { return a.i==b.i && eq(&a.f,&b.f,sizeof(a.f)); }
BF FN(echo_BF)(BF x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
BF FN(p7_BF)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, BF x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
BF FN(p8_BF)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, BF x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_BFPad(BFPad a,BFPad b) { return a.i==b.i && eq(&a.f,&b.f,sizeof(a.f)); }
BFPad FN(echo_BFPad)(BFPad x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
BFPad FN(p7_BFPad)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, BFPad x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
BFPad FN(p8_BFPad)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, BFPad x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_FD(FD a,FD b) { return eq(&a.f,&b.f,sizeof(a.f)) && eq(&a.d,&b.d,sizeof(a.d)); }
FD FN(echo_FD)(FD x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
FD FN(p7_FD)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, FD x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
FD FN(p8_FD)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, FD x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
static int same_Gap(Gap a,Gap b) { return eq(&a.f,&b.f,sizeof(a.f)) && eq(&a.g,&b.g,sizeof(a.g)); }
Gap FN(echo_Gap)(Gap x) { if(sizeof x) ((unsigned char*)&x)[0]^=0x5a; return x; }
Gap FN(p7_Gap)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, Gap x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
Gap FN(p8_Gap)(unsigned long a0, unsigned long a1, unsigned long a2, unsigned long a3, unsigned long a4, unsigned long a5, unsigned long a6, unsigned long a7, Gap x, unsigned long tail) { if(a0!=1 || a1!=2 || a2!=3 || a3!=4 || a4!=5 || a5!=6 || a6!=7 || a7!=8 || tail!=93) ((unsigned char*)&x)[0]^=0x5a; return x; }
F2 FN(fp7)(float a,float b,float c,float d,float e,float f,float g,F2 x,float tail) { if(a!=1.f||b!=2.f||c!=3.f||d!=4.f||e!=5.f||f!=6.f||g!=7.f||tail!=9.f) x.x[0]=0.f; return x; }
FI FN(gi8)(unsigned long a,unsigned long b,unsigned long c,unsigned long d,unsigned long e,unsigned long f,unsigned long g,unsigned long h,FI x,float tail) { if(a!=1||b!=2||c!=3||d!=4||e!=5||f!=6||g!=7||h!=8||tail!=9.f) x.i=0; return x; }
static int forwarded(va_list ap) {
  B5 b5=va_arg(ap,B5); A8 a8=va_arg(ap,A8); B16 b16=va_arg(ap,B16); B80 b80=va_arg(ap,B80);
  F2 f=va_arg(ap,F2); A16 a16=va_arg(ap,A16); float promoted=(float)va_arg(ap,double);
  B5 e5; B16 e16; B80 e80; A16 ea16;
  fill(&e5,sizeof e5); fill(&e16,sizeof e16); fill(&e80,sizeof e80); fill(&ea16,sizeof ea16);
  return same_B5(b5,e5)&&a8.n==0x123456789abcdef0ULL&&same_B16(b16,e16)&&same_B80(b80,e80)&&f.x[0]==3.f&&f.x[1]==4.f&&same_A16(a16,ea16)&&promoted==1.25f;
}
F2 FN(variadic)(F2 named,int n,...) { va_list ap,copy; F2 result=named; int ok;
  va_start(ap,n); va_copy(copy,ap); ok=forwarded(ap)&&forwarded(copy); va_end(copy); va_end(ap);
  if(!ok||n!=7) result.x[0]=0.f; return result; }
F2 FN(va_echo)(int tag,...) { va_list ap; F2 r; va_start(ap,tag); r=va_arg(ap,F2); va_end(ap); ((unsigned char*)&r)[0]^=0x5a; return r; }
unsigned long FN(alignment)(Aligned a) { return (unsigned long)&a & 31; }
unsigned FN(mutate)(B80 a) { a.b[0]^=0x5a; return a.b[0]; }
float FN(sum)(F2 x) { return x.x[0]+x.x[1]; }
unsigned long long FN(number)(F1 x) { return x.x==1.25f ? 0x123456789abcdef0ULL : 0; }
int FN(convert)(F1 x,signed char c,float y,...) { va_list ap; float f; int n; va_start(ap,y); f=(float)va_arg(ap,double); n=va_arg(ap,int); va_end(ap); return x.x==1.25f && c==44 && y==2.f && f==1.25f && n==-7; }
int FN(test)(void) {
  { B1 a,b; fill(&a,sizeof a); B1 expected=a; B1 (*volatile fp)(B1)=OTHER(echo_B1); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_B1)(a); if(!same_B1(expected,b)) return 10;
    b=fp(a); if(!same_B1(expected,b)) return 50;
    b=OTHER(p7_B1)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_B1(a,b)) return 90;
    b=OTHER(p8_B1)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_B1(a,b)) return 125;
  }
  { B2 a,b; fill(&a,sizeof a); B2 expected=a; B2 (*volatile fp)(B2)=OTHER(echo_B2); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_B2)(a); if(!same_B2(expected,b)) return 11;
    b=fp(a); if(!same_B2(expected,b)) return 51;
    b=OTHER(p7_B2)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_B2(a,b)) return 91;
    b=OTHER(p8_B2)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_B2(a,b)) return 126;
  }
  { B3 a,b; fill(&a,sizeof a); B3 expected=a; B3 (*volatile fp)(B3)=OTHER(echo_B3); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_B3)(a); if(!same_B3(expected,b)) return 12;
    b=fp(a); if(!same_B3(expected,b)) return 52;
    b=OTHER(p7_B3)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_B3(a,b)) return 92;
    b=OTHER(p8_B3)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_B3(a,b)) return 127;
  }
  { B4 a,b; fill(&a,sizeof a); B4 expected=a; B4 (*volatile fp)(B4)=OTHER(echo_B4); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_B4)(a); if(!same_B4(expected,b)) return 13;
    b=fp(a); if(!same_B4(expected,b)) return 53;
    b=OTHER(p7_B4)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_B4(a,b)) return 93;
    b=OTHER(p8_B4)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_B4(a,b)) return 128;
  }
  { B5 a,b; fill(&a,sizeof a); B5 expected=a; B5 (*volatile fp)(B5)=OTHER(echo_B5); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_B5)(a); if(!same_B5(expected,b)) return 14;
    b=fp(a); if(!same_B5(expected,b)) return 54;
    b=OTHER(p7_B5)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_B5(a,b)) return 94;
    b=OTHER(p8_B5)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_B5(a,b)) return 129;
  }
  { B7 a,b; fill(&a,sizeof a); B7 expected=a; B7 (*volatile fp)(B7)=OTHER(echo_B7); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_B7)(a); if(!same_B7(expected,b)) return 15;
    b=fp(a); if(!same_B7(expected,b)) return 55;
    b=OTHER(p7_B7)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_B7(a,b)) return 95;
    b=OTHER(p8_B7)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_B7(a,b)) return 130;
  }
  { B8 a,b; fill(&a,sizeof a); B8 expected=a; B8 (*volatile fp)(B8)=OTHER(echo_B8); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_B8)(a); if(!same_B8(expected,b)) return 16;
    b=fp(a); if(!same_B8(expected,b)) return 56;
    b=OTHER(p7_B8)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_B8(a,b)) return 96;
    b=OTHER(p8_B8)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_B8(a,b)) return 131;
  }
  { B9 a,b; fill(&a,sizeof a); B9 expected=a; B9 (*volatile fp)(B9)=OTHER(echo_B9); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_B9)(a); if(!same_B9(expected,b)) return 17;
    b=fp(a); if(!same_B9(expected,b)) return 57;
    b=OTHER(p7_B9)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_B9(a,b)) return 97;
    b=OTHER(p8_B9)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_B9(a,b)) return 132;
  }
  { B12 a,b; fill(&a,sizeof a); B12 expected=a; B12 (*volatile fp)(B12)=OTHER(echo_B12); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_B12)(a); if(!same_B12(expected,b)) return 18;
    b=fp(a); if(!same_B12(expected,b)) return 58;
    b=OTHER(p7_B12)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_B12(a,b)) return 98;
    b=OTHER(p8_B12)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_B12(a,b)) return 133;
  }
  { B15 a,b; fill(&a,sizeof a); B15 expected=a; B15 (*volatile fp)(B15)=OTHER(echo_B15); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_B15)(a); if(!same_B15(expected,b)) return 19;
    b=fp(a); if(!same_B15(expected,b)) return 59;
    b=OTHER(p7_B15)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_B15(a,b)) return 99;
    b=OTHER(p8_B15)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_B15(a,b)) return 134;
  }
  { B16 a,b; fill(&a,sizeof a); B16 expected=a; B16 (*volatile fp)(B16)=OTHER(echo_B16); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_B16)(a); if(!same_B16(expected,b)) return 20;
    b=fp(a); if(!same_B16(expected,b)) return 60;
    b=OTHER(p7_B16)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_B16(a,b)) return 100;
    b=OTHER(p8_B16)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_B16(a,b)) return 135;
  }
  { B17 a,b; fill(&a,sizeof a); B17 expected=a; B17 (*volatile fp)(B17)=OTHER(echo_B17); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_B17)(a); if(!same_B17(expected,b)) return 21;
    b=fp(a); if(!same_B17(expected,b)) return 61;
    b=OTHER(p7_B17)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_B17(a,b)) return 101;
    b=OTHER(p8_B17)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_B17(a,b)) return 136;
  }
  { B24 a,b; fill(&a,sizeof a); B24 expected=a; B24 (*volatile fp)(B24)=OTHER(echo_B24); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_B24)(a); if(!same_B24(expected,b)) return 22;
    b=fp(a); if(!same_B24(expected,b)) return 62;
    b=OTHER(p7_B24)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_B24(a,b)) return 102;
    b=OTHER(p8_B24)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_B24(a,b)) return 137;
  }
  { B80 a,b; fill(&a,sizeof a); B80 expected=a; B80 (*volatile fp)(B80)=OTHER(echo_B80); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_B80)(a); if(!same_B80(expected,b)) return 23;
    b=fp(a); if(!same_B80(expected,b)) return 63;
    b=OTHER(p7_B80)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_B80(a,b)) return 103;
    b=OTHER(p8_B80)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_B80(a,b)) return 138;
  }
  { B4096 a,b; fill(&a,sizeof a); B4096 expected=a; B4096 (*volatile fp)(B4096)=OTHER(echo_B4096); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_B4096)(a); if(!same_B4096(expected,b)) return 24;
    b=fp(a); if(!same_B4096(expected,b)) return 64;
    b=OTHER(p7_B4096)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_B4096(a,b)) return 104;
    b=OTHER(p8_B4096)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_B4096(a,b)) return 139;
  }
  { F1 a,b; fill(&a,sizeof a); a.x=1.25f; F1 expected=a; F1 (*volatile fp)(F1)=OTHER(echo_F1); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_F1)(a); if(!same_F1(expected,b)) return 25;
    b=fp(a); if(!same_F1(expected,b)) return 65;
    b=OTHER(p7_F1)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_F1(a,b)) return 105;
    b=OTHER(p8_F1)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_F1(a,b)) return 140;
  }
  { F2 a,b; fill(&a,sizeof a); a.x[0]=3.f; a.x[1]=4.f; F2 expected=a; F2 (*volatile fp)(F2)=OTHER(echo_F2); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_F2)(a); if(!same_F2(expected,b)) return 26;
    b=fp(a); if(!same_F2(expected,b)) return 66;
    b=OTHER(p7_F2)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_F2(a,b)) return 106;
    b=OTHER(p8_F2)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_F2(a,b)) return 141;
  }
  { Nested a,b; fill(&a,sizeof a); a.a[0].x=1.25f; a.a[1].x=-2.5f; Nested expected=a; Nested (*volatile fp)(Nested)=OTHER(echo_Nested); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_Nested)(a); if(!same_Nested(expected,b)) return 27;
    b=fp(a); if(!same_Nested(expected,b)) return 67;
    b=OTHER(p7_Nested)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_Nested(a,b)) return 107;
    b=OTHER(p8_Nested)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_Nested(a,b)) return 142;
  }
  { FI a,b; fill(&a,sizeof a); a.x=-0.f; a.i=-123; FI expected=a; FI (*volatile fp)(FI)=OTHER(echo_FI); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_FI)(a); if(!same_FI(expected,b)) return 28;
    b=fp(a); if(!same_FI(expected,b)) return 68;
    b=OTHER(p7_FI)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_FI(a,b)) return 108;
    b=OTHER(p8_FI)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_FI(a,b)) return 143;
  }
  { IF a,b; fill(&a,sizeof a); a.i=987; a.x=1.25f; IF expected=a; IF (*volatile fp)(IF)=OTHER(echo_IF); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_IF)(a); if(!same_IF(expected,b)) return 29;
    b=fp(a); if(!same_IF(expected,b)) return 69;
    b=OTHER(p7_IF)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_IF(a,b)) return 109;
    b=OTHER(p8_IF)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_IF(a,b)) return 144;
  }
  { FP a,b; fill(&a,sizeof a); a.x=1.25f; a.p=&a; FP expected=a; FP (*volatile fp)(FP)=OTHER(echo_FP); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_FP)(a); if(!same_FP(expected,b)) return 30;
    b=fp(a); if(!same_FP(expected,b)) return 70;
    b=OTHER(p7_FP)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_FP(a,b)) return 110;
    b=OTHER(p8_FP)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_FP(a,b)) return 145;
  }
  { Packed a,b; fill(&a,sizeof a); a.c=17; a.x=1.25f; Packed expected=a; Packed (*volatile fp)(Packed)=OTHER(echo_Packed); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_Packed)(a); if(!same_Packed(expected,b)) return 31;
    b=fp(a); if(!same_Packed(expected,b)) return 71;
    b=OTHER(p7_Packed)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_Packed(a,b)) return 111;
    b=OTHER(p8_Packed)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_Packed(a,b)) return 146;
  }
  { Aligned a,b; fill(&a,sizeof a); a.x=1.25f; Aligned expected=a; Aligned (*volatile fp)(Aligned)=OTHER(echo_Aligned); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_Aligned)(a); if(!same_Aligned(expected,b)) return 32;
    b=fp(a); if(!same_Aligned(expected,b)) return 72;
    b=OTHER(p7_Aligned)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_Aligned(a,b)) return 112;
    b=OTHER(p8_Aligned)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_Aligned(a,b)) return 147;
  }
  { U a,b; fill(&a,sizeof a); U expected=a; U (*volatile fp)(U)=OTHER(echo_U); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_U)(a); if(!same_U(expected,b)) return 33;
    b=fp(a); if(!same_U(expected,b)) return 73;
    b=OTHER(p7_U)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_U(a,b)) return 113;
    b=OTHER(p8_U)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_U(a,b)) return 148;
  }
  { Bits a,b; fill(&a,sizeof a); a.a=5; a.b=-37; a.c=311; Bits expected=a; Bits (*volatile fp)(Bits)=OTHER(echo_Bits); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_Bits)(a); if(!same_Bits(expected,b)) return 34;
    b=fp(a); if(!same_Bits(expected,b)) return 74;
    b=OTHER(p7_Bits)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_Bits(a,b)) return 114;
    b=OTHER(p8_Bits)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_Bits(a,b)) return 149;
  }
  { D a,b; fill(&a,sizeof a); a.d=1.25; D expected=a; D (*volatile fp)(D)=OTHER(echo_D); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_D)(a); if(!same_D(expected,b)) return 35;
    b=fp(a); if(!same_D(expected,b)) return 75;
    b=OTHER(p7_D)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_D(a,b)) return 115;
    b=OTHER(p8_D)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_D(a,b)) return 150;
  }
  { A8 a,b; fill(&a,sizeof a); a.n=0x123456789abcdef0ULL; A8 expected=a; A8 (*volatile fp)(A8)=OTHER(echo_A8); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_A8)(a); if(!same_A8(expected,b)) return 36;
    b=fp(a); if(!same_A8(expected,b)) return 76;
    b=OTHER(p7_A8)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_A8(a,b)) return 116;
    b=OTHER(p8_A8)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_A8(a,b)) return 151;
  }
  { A16 a,b; fill(&a,sizeof a); A16 expected=a; A16 (*volatile fp)(A16)=OTHER(echo_A16); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_A16)(a); if(!same_A16(expected,b)) return 37;
    b=fp(a); if(!same_A16(expected,b)) return 77;
    b=OTHER(p7_A16)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_A16(a,b)) return 117;
    b=OTHER(p8_A16)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_A16(a,b)) return 152;
  }
  { Empty a,b; fill(&a,sizeof a); Empty expected=a; Empty (*volatile fp)(Empty)=OTHER(echo_Empty); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_Empty)(a); if(!same_Empty(expected,b)) return 38;
    b=fp(a); if(!same_Empty(expected,b)) return 78;
    b=OTHER(p7_Empty)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_Empty(a,b)) return 118;
    b=OTHER(p8_Empty)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_Empty(a,b)) return 153;
  }
  { BF a,b; fill(&a,sizeof a); a.f=1.25f; a.i=37; BF expected=a; BF (*volatile fp)(BF)=OTHER(echo_BF); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_BF)(a); if(!same_BF(expected,b)) return 39;
    b=fp(a); if(!same_BF(expected,b)) return 79;
    b=OTHER(p7_BF)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_BF(a,b)) return 119;
    b=OTHER(p8_BF)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_BF(a,b)) return 154;
  }
  { BFPad a,b; fill(&a,sizeof a); a.f=1.25f; a.i=37; BFPad expected=a; BFPad (*volatile fp)(BFPad)=OTHER(echo_BFPad); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_BFPad)(a); if(!same_BFPad(expected,b)) return 40;
    b=fp(a); if(!same_BFPad(expected,b)) return 80;
    b=OTHER(p7_BFPad)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_BFPad(a,b)) return 120;
    b=OTHER(p8_BFPad)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_BFPad(a,b)) return 155;
  }
  { FD a,b; fill(&a,sizeof a); a.f=1.25f; a.d=2.5; FD expected=a; FD (*volatile fp)(FD)=OTHER(echo_FD); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_FD)(a); if(!same_FD(expected,b)) return 41;
    b=fp(a); if(!same_FD(expected,b)) return 81;
    b=OTHER(p7_FD)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_FD(a,b)) return 121;
    b=OTHER(p8_FD)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_FD(a,b)) return 156;
  }
  { Gap a,b; fill(&a,sizeof a); a.f=1.25f; a.g=2.5f; Gap expected=a; Gap (*volatile fp)(Gap)=OTHER(echo_Gap); if(sizeof expected) ((unsigned char*)&expected)[0]^=0x5a;
    b=OTHER(echo_Gap)(a); if(!same_Gap(expected,b)) return 42;
    b=fp(a); if(!same_Gap(expected,b)) return 82;
    b=OTHER(p7_Gap)(1, 2, 3, 4, 5, 6, 7, a, 93); if(!same_Gap(a,b)) return 122;
    b=OTHER(p8_Gap)(1, 2, 3, 4, 5, 6, 7, 8, a, 93); if(!same_Gap(a,b)) return 157;
  }
  { F2 a={{3.f,4.f}}, b; FI fi={1.25f,17}, r; B5 b5; A8 a8={0x123456789abcdef0ULL}; B16 b16; B80 b80; A16 a16;
    b=OTHER(fp7)(1.f,2.f,3.f,4.f,5.f,6.f,7.f,a,9.f); if(!same_F2(a,b)) return 180;
    r=OTHER(gi8)(1,2,3,4,5,6,7,8,fi,9.f); if(!same_FI(fi,r)) return 181;
    fill(&b5,sizeof b5); fill(&b16,sizeof b16); fill(&b80,sizeof b80); fill(&a16,sizeof a16);
    b=OTHER(variadic)(a,7,b5,a8,b16,b80,a,a16,1.25f); if(!same_F2(a,b)) return 182;
  }
  { Aligned a; B80 b; fill(&a,sizeof a); fill(&b,sizeof b); if(OTHER(alignment)(a)) return 183;
    if(OTHER(mutate)(b)!=(17^0x5a)||b.b[0]!=17) return 184; }
  { F2 x={{3.f,4.f}}; F1 y={1.25f}; if(OTHER(sum)(x)!=7.f || OTHER(number)(y)!=0x123456789abcdef0ULL) return 187; }
  { F1 x={1.25f}; if(!OTHER(convert)(x,300,2,1.25f,(signed char)-7)) return 188; }
  { F2 a={{3.f,4.f}}, expected=a,b; F2 (*volatile fn)()=(F2 (*)())OTHER(echo_F2); ((unsigned char*)&expected)[0]^=0x5a; b=fn(a); if(!same_F2(expected,b)) return 189; }
  { unsigned patterns[]={0,0x80000000u,1,0x007fffffu,0x7f800000u,0x7fc12345u,0x7f812345u,0xff812345u}; unsigned i;
    for(i=0;i<8;++i) { union { unsigned u; float f; } u,v; F2 a,b; u.u=patterns[i]; v.u=patterns[7-i]; a.x[0]=u.f; a.x[1]=v.f; F2 expected=a; ((unsigned char*)&expected)[0]^=0x5a;
      b=OTHER(echo_F2)(a); if(!eq(&expected,&b,sizeof b)) return 185;
      b=OTHER(va_echo)(7,a); if(!eq(&expected,&b,sizeof b)) return 186;
    } }
  return 0;
}
