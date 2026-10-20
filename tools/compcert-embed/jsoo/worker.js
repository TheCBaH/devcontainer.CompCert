// Web Worker wrapper for the bundle built from compcert_jsoo.ml.
//
//   const w = new Worker("worker.js");
//   w.postMessage({ id, source, options });
//   w.onmessage = (e) => e.data   // { id, ok, asm | kind, message }
//
// The bundle (compcert_jsoo.bc.js) is loaded next to this file. One Worker
// compiles one unit at a time; after a "too_deep" result, start a new Worker.
importScripts("compcert_jsoo.bc.js");

self.onmessage = (e) => {
  const { id, source, options } = e.data;
  const r = self.CompCert.compile(source, options);
  self.postMessage({ id, ...r });
};
