// One compile of one shape at one size, in a fresh process (so the engine runs
// cold, as in a freshly started Worker):
//   node --stack-size=984 try.js <shape> <N>
// Prints "<kind> <seconds>" where kind is ok, diagnostics, too_deep, ... .
// Environment: CC_BUNDLE (a jsoo script, a Melange CommonJS module or an
// ES-module bundle).
const path = require("path");
const { shapes } = require("./gen.js");
const bundle = path.resolve(process.env.CC_BUNDLE);

(async () => {
  const mod = bundle.endsWith(".mjs") ? await import(require("url").pathToFileURL(bundle).href) : require(bundle);
  // wasm_of_ocaml instantiates asynchronously and sets CompCert when done
  if (!globalThis.CompCert && !mod.CompCert && !mod.compile) {
    while (!globalThis.CompCert) await new Promise((r) => setTimeout(r, 2));
  }
  const CompCert = globalThis.CompCert || mod.CompCert || mod;
  const t = Date.now();
  const r = CompCert.compile(shapes[process.argv[2]](+process.argv[3]), { name: `${process.argv[2]}.c` });
  console.log(`${r.ok ? "ok" : r.kind} ${((Date.now() - t) / 1000).toFixed(1)}`);
})();
