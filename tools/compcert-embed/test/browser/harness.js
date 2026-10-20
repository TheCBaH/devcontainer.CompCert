// Page-side code of the browser tests: Workers over each backend, a corpus
// comparison, timing and heap measurements, and the stack-limit sweep. All of
// it runs inside the browser engine under test; run.mjs only starts it and
// reads the report.

function spawn(backend) {
  const t0 = performance.now();
  const w = backend === "mel" ? new Worker("worker-mel.mjs", { type: "module" }) : new Worker("worker-jsoo.js");
  let nextId = 1;
  const pending = new Map();
  let ready;
  const readyP = new Promise((res, rej) => { ready = { res, rej }; });
  w.onmessage = (e) => {
    if (e.data.type === "ready") return ready.res(performance.now() - t0);
    const p = pending.get(e.data.id);
    if (p) { pending.delete(e.data.id); p.res(e.data); }
  };
  w.onerror = (e) => {
    const err = new Error(e.message || "worker error");
    ready.rej(err);
    for (const p of pending.values()) p.rej(err);
    pending.clear();
  };
  return {
    loadMs: readyP,
    call(msg) {
      return new Promise((res, rej) => {
        const id = nextId++;
        pending.set(id, { res, rej });
        w.postMessage({ ...msg, id });
      });
    },
    terminate() { w.terminate(); },
  };
}

async function text(url) {
  const r = await fetch(url);
  if (!r.ok) throw new Error(`${url}: ${r.status}`);
  return r.text();
}

// The language of the expected files: the native embed build's .s/.err/.status.
function lines3(s) { return s.split("\n").slice(2).join("\n"); }

async function runSubset(backend, manifest) {
  const w = spawn(backend);
  const loadMs = await w.loadMs;
  const results = { backend, loadMs, files: manifest.length, same: 0, diff: [], times: [] };
  for (const f of manifest) {
    const source = await text(`corpus/${f.name}.i`);
    const [expAsm, expErr, expStatus] = await Promise.all([
      text(`expected/${f.name}.s`), text(`expected/${f.name}.err`), text(`expected/${f.name}.status`),
    ]);
    const r = await w.call({ type: "compile", source, name: f.file });
    results.times.push({ name: f.name, ms: r.ms });
    const expectedOk = expStatus.trim() === "0";
    const same = r.ok === expectedOk && (r.ok ? lines3(r.asm) === lines3(expAsm) && r.diagnostics === expErr : r.diagnostics === expErr);
    if (same) results.same++; else results.diff.push(f.name);
  }
  w.terminate();
  return results;
}

async function measure(backend, f, repeats) {
  const w = spawn(backend);
  await w.loadMs;
  const source = await text(`corpus/${f.name}.i`);
  const first = await w.call({ type: "compile", source, name: f.file });
  const steady = [];
  for (let i = 0; i < 10; i++) steady.push((await w.call({ type: "compile", source, name: f.file })).ms);
  steady.sort((a, b) => a - b);
  const rep = await w.call({ type: "repeat", source, name: f.file, times: repeats });
  w.terminate();
  return { file: f.name, firstMs: first.ms, steadyMs: steady[Math.floor(steady.length / 2)], repeats, heap0: rep.heap0, heap1: rep.heap1, repeatMs: rep.ms };
}

// The same compiles on the page's own thread, where Chromium reports the heap
// (with --enable-precise-memory-info) and can be asked to collect
// (--js-flags=--expose-gc). Compile time per batch of 20 is reported either way:
// a leak shows as batches getting slower.
async function measureMain(backend, f, repeats) {
  let compile;
  if (backend === "mel") {
    compile = (await import("./compcert_melange.min.mjs")).compile;
  } else {
    await new Promise((res, rej) => {
      const s = document.createElement("script");
      s.src = "compcert_jsoo.bc.js";
      s.onload = res;
      s.onerror = rej;
      document.head.appendChild(s);
    });
    compile = (src, o) => window.CompCert.compile(src, o);
  }
  const source = await text(`corpus/${f.name}.i`);
  const used = () => (performance.memory ? performance.memory.usedJSHeapSize : null);
  const collect = () => (typeof gc === "function" ? gc() : undefined);
  compile(source, { name: f.file });
  collect();
  const heap0 = used();
  const batches = [];
  for (let i = 0; i < repeats; i += 20) {
    const t = performance.now();
    for (let j = 0; j < 20 && i + j < repeats; j++) compile(source, { name: f.file });
    batches.push(performance.now() - t);
  }
  collect();
  return { file: f.name, repeats, heap0, heap1: used(), batchMs: batches };
}

// One compile of one shape in a fresh Worker: "ok", "too_deep", ... or "crash".
async function probe(backend, shape, n, budgetMs) {
  const w = spawn(backend);
  try {
    await w.loadMs;
    const r = await Promise.race([
      w.call({ type: "shape", shape, n }),
      new Promise((res) => setTimeout(() => res({ ok: false, kind: "timeout" }), budgetMs)),
    ]);
    return r.ok ? "ok" : r.kind === "diagnostics" ? "ok" : r.kind || "crash";
  } catch (e) {
    return "crash";
  } finally {
    w.terminate();
  }
}

async function sweep(backend, shapes, limit, budgetMs) {
  const out = {};
  for (const shape of shapes) {
    let lo = 0, hi = 0, n = 250, slow = false, failure = "";
    const passes = async (k) => {
      const t = performance.now();
      const kind = await probe(backend, shape, k, budgetMs);
      if (performance.now() - t > budgetMs / 2) slow = true;
      if (kind === "ok") return true;
      failure = kind;
      return false;
    };
    while (n <= limit) {
      if (await passes(n)) { lo = n; n *= 2; if (slow) break; } else { hi = n; break; }
    }
    if (hi) {
      while (hi - lo > Math.max(1, lo / 20)) {
        const mid = Math.floor((lo + hi) / 2);
        if (await passes(mid)) lo = mid; else hi = mid;
      }
    }
    out[shape] = { ok: lo, fails: hi || null, answer: hi ? failure : slow ? "stopped: slow" : "limit" };
  }
  return out;
}

// Each (shape, N) of a limits file in a fresh Worker: the answer must be "ok".
async function checkLimits(backend, limitsText, budgetMs) {
  const out = {};
  for (const line of limitsText.split("\n")) {
    if (!line.trim() || line.startsWith("#")) continue;
    const [shape, n, ...flags] = line.trim().split(/\s+/);
    if (flags.includes("slow")) continue;
    out[shape] = { n: +n, answer: await probe(backend, shape, +n, budgetMs) };
  }
  return out;
}

window.harness = { runSubset, measure, measureMain, sweep, checkLimits };
