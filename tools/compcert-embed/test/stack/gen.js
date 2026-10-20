// C inputs of one shape, parameterized by N (see sweep.js).
const rep = (n, f) => Array.from({ length: n }, (_, i) => f(i)).join("");

exports.shapes = {
  globals: (n) => rep(n, (i) => `int g${i} = ${i};\n`),
  functions: (n) => rep(n, (i) => `int f${i}(int x) { return x + ${i}; }\n`),
  statements: (n) => `int f(int x) {\n${rep(n, () => "  x = x + 1;\n")}  return x;\n}\n`,
  exprchain: (n) => `int f(int x) { return x${rep(n, () => " + 1")}; }\n`,
  exprnest: (n) => `int f(int x) { return ${"(".repeat(n)}x${")".repeat(n)}; }\n`,
  addnest: (n) => `int f(int x) { return ${"(1 + ".repeat(n)}x${")".repeat(n)}; }\n`,
  blocknest: (n) => `int f(int x) {\n${"{ ".repeat(n)}x = 1;${" }".repeat(n)}\n  return x;\n}\n`,
  ifnest: (n) => `int f(int x) {\n${"if (x) { ".repeat(n)}x = 1;${" }".repeat(n)}\n  return x;\n}\n`,
  elseif: (n) =>
    `int f(int x) {\n  if (x == 0) return 0;\n${rep(n, (i) => `  else if (x == ${i + 1}) return ${i + 1};\n`)}  return -1;\n}\n`,
  switchcases: (n) =>
    `int f(int x) {\n  switch (x) {\n${rep(n, (i) => `  case ${i}: return ${i * 3};\n`)}  }\n  return -1;\n}\n`,
  strings: (n) => `const char *s[] = {\n${rep(n, (i) => `  "string number ${i}",\n`)}};\n`,
  stringstmts: (n) => `int f(const char **p) {\n${rep(n, (i) => `  p[0] = "s${i}";\n`)}  return 0;\n}\n`,
  initelems: (n) => `int a[] = {${rep(n, (i) => `${i},`)}};\n`,
  structfields: (n) => `struct s {\n${rep(n, (i) => `  int m${i};\n`)}};\nstruct s v;\n`,
  callargs: (n) =>
    `int g(${Array.from({ length: n }, (_, i) => `int a${i}`).join(", ")});\nint f(void) { return g(${Array.from({ length: n }, (_, i) => i).join(", ")}); }\n`,
  localvars: (n) => `int f(int x) {\n${rep(n, (i) => `  int v${i} = x + ${i};\n`)}  return v0;\n}\n`,
};

if (require.main === module) process.stdout.write(exports.shapes[process.argv[2]](+process.argv[3]));
