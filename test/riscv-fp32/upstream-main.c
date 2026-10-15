#if defined(TEST_expr3)
struct s { int a[1]; };
extern int f(struct s *);
int main(void) {
  struct s x;
  return f((void *)0) != 0 || f(&x) != 1;
}
#elif defined(TEST_expr4)
extern int f(int);
int main(void) { return f(0) != 1 || f(1) != 0 || f(-1) != 0; }
#elif defined(TEST_extern1)
extern int f(void);
int main(void) { return f() != 5; }
#elif defined(TEST_ptrs1)
extern const char *f(char *, const char *);
int main(void) {
  char a, b;
  return f(&a, &a) != &a || f(&a, &b) != &b ||
         f(&a, (void *)0) != (void *)0;
}
#elif defined(TEST_struct9)
struct S1 { unsigned char f0; short f1; };
extern struct S1 g_77;
extern void func_1(void);
int main(void) {
  func_1();
  return g_77.f0 != 0xAD || g_77.f1 != (short)0x9086;
}
#elif defined(TEST_types1)
extern int f(int);
int main(void) { return f(0) != 4 || f(-123) != 4; }
#elif defined(TEST_bitfields)
extern int f(void);
int main(void) { return f() != 2; }
#elif defined(TEST_issue216)
struct list { unsigned head; struct list *tail; };
extern struct list three[];
extern int f(int);
int main(void) {
  return f(-42) != -42 || three[0].head != 1 ||
         three[0].tail != three + 1 || three[1].head != 2 ||
         three[1].tail != three + 2 || three[2].head != 3 ||
         three[2].tail != (void *)0;
}
#else
#error Select an upstream test
#endif
