// CLI over a CompCert bundle, for the differential driver:
//   node --stack-size=984 compile.js <file.i>
// Environment: CC_BUNDLE, the jsoo bundle (default: ./compcert_jsoo.bc.js);
// CC_OPT, one of O0 O1 O2 Os (default O2); CC_DEBUG=1 for -g.
// The assembly goes to stdout, diagnostics to stderr; exit 0 on success, 1 on
// a compile error.
const fs = require("fs");
const path = require("path");
const bundle = path.resolve(process.env.CC_BUNDLE || "compcert_jsoo.bc.js");
const file = process.argv[2];

async function load() {
  // A .mjs bundle is an ES module; the others are scripts.
  const mod = bundle.endsWith(".mjs") ? await import(require("url").pathToFileURL(bundle).href) : require(bundle);
  // jsoo exports CompCert; Melange exports compile directly; wasm_of_ocaml
  // instantiates its module asynchronously and sets CompCert when done.
  if (!globalThis.CompCert && !mod.CompCert && !mod.compile) {
    while (!globalThis.CompCert) await new Promise((r) => setTimeout(r, 2));
  }
  return globalThis.CompCert || mod.CompCert || mod;
}

load().then(main);

function main(CompCert) {
  const source = fs.readFileSync(file, "utf8");
  const r = CompCert.compile(source, { name: file, opt: process.env.CC_OPT || "O2", debug: process.env.CC_DEBUG === "1" });
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
}
