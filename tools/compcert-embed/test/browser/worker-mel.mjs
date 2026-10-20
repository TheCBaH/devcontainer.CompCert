// Module Worker over the bundled Melange ES module (served next to this file).
import { compile } from "./compcert_melange.min.mjs";

// gen.js is a classic script: load it through fetch and Function.
self.exports = {};
const genSource = await (await fetch("gen.js")).text();
new Function("exports", genSource)(self.exports);

function heap() {
  return self.performance && self.performance.memory ? self.performance.memory.usedJSHeapSize : null;
}

self.postMessage({ type: "ready" });

self.onmessage = (e) => {
  const m = e.data;
  const t = performance.now();
  let r;
  if (m.type === "compile") {
    r = compile(m.source, { name: m.name, opt: "O2" });
  } else if (m.type === "shape") {
    r = compile(self.exports.shapes[m.shape](m.n), { name: `${m.shape}.c` });
  } else if (m.type === "repeat") {
    const h0 = heap();
    for (let i = 0; i < m.times; i++) r = compile(m.source, { name: m.name, opt: "O2" });
    self.postMessage({ id: m.id, ok: r.ok, ms: performance.now() - t, heap0: h0, heap1: heap() });
    return;
  }
  self.postMessage({
    id: m.id,
    ok: r.ok,
    kind: r.kind,
    asm: m.type === "compile" ? r.asm : undefined,
    diagnostics: m.type === "compile" ? (r.ok ? r.diagnostics : r.message) : undefined,
    ms: performance.now() - t,
  });
};
