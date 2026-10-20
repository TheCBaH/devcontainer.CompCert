// CLI over a CompCert bundle, for the differential driver:
//   node --stack-size=984 compile.js <file.i>
// Environment: CC_BUNDLE, the jsoo bundle (default: ./compcert_jsoo.bc.js);
// CC_OPT, one of O0 O1 O2 Os (default O2).
// The assembly goes to stdout, diagnostics to stderr; exit 0 on success, 1 on
// a compile error.
const fs = require("fs");
const path = require("path");
const bundle = path.resolve(process.env.CC_BUNDLE || "compcert_jsoo.bc.js");
require(bundle);
const CompCert = globalThis.CompCert || module.exports.CompCert || require(bundle).CompCert;
const file = process.argv[2];
const source = fs.readFileSync(file, "utf8");
const r = CompCert.compile(source, { name: file, opt: process.env.CC_OPT || "O2" });
if (r.ok) {
  if (r.diagnostics) fs.writeSync(2, r.diagnostics);
  fs.writeSync(1, r.asm);
  process.exit(0);
}
if (r.kind === "diagnostics") {
  fs.writeSync(2, r.message);
  process.exit(1);
}
fs.writeSync(2, `error (${r.kind}): ${r.message}\n`);
process.exit(3);
