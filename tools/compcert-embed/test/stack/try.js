// One compile of one shape at one size, in a fresh process (so the engine runs
// cold, as in a freshly started Worker):
//   node --stack-size=984 try.js <shape> <N>
// Prints "<kind> <seconds>" where kind is ok, diagnostics, too_deep, ... .
// Environment: CC_BUNDLE.
const path = require("path");
const { shapes } = require("./gen.js");
require(path.resolve(process.env.CC_BUNDLE));
const CompCert = globalThis.CompCert || require(path.resolve(process.env.CC_BUNDLE)).CompCert;
const t = Date.now();
const r = CompCert.compile(shapes[process.argv[2]](+process.argv[3]), { name: `${process.argv[2]}.c` });
console.log(`${r.ok ? "ok" : r.kind} ${((Date.now() - t) / 1000).toFixed(1)}`);
