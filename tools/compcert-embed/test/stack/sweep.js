// Largest N each shape compiles to at the engine's stack size, each probe in a
// fresh process:
//   node sweep.js [--stack KB] [--limit N] [--budget S] [shape ...]
// Environment: CC_BUNDLE, as for try.js. A shape passes at N when the compile
// answers ok or with a diagnostic; "too_deep" is the overflow answer. Each
// shape doubles N until it fails (or reaches --limit), then bisects to 2%.
// --budget stops a shape once one compile exceeds S seconds (the point is
// stack depth, not speed). Prints one line per shape: largest passing N, the
// first failing N (or "-") and the failing answer.
const { spawnSync } = require("child_process");
const path = require("path");
const { shapes } = require("./gen.js");

let limit = 100000, budget = 60, stack = 984;
const names = [];
const a = process.argv.slice(2);
for (let i = 0; i < a.length; i++) {
  if (a[i] === "--limit") limit = +a[++i];
  else if (a[i] === "--budget") budget = +a[++i];
  else if (a[i] === "--stack") stack = +a[++i];
  else names.push(a[i]);
}

let slow = false, failure = "";
function passes(shape, n) {
  const r = spawnSync(process.execPath, [`--stack-size=${stack}`, path.join(__dirname, "try.js"), shape, String(n)], {
    encoding: "utf8", env: process.env, maxBuffer: 1 << 20,
  });
  const [kind, secs] = (r.stdout || "").trim().split(" ");
  if (+secs > budget) slow = true;
  if (kind === "ok" || kind === "diagnostics") return true;
  failure = kind || `crash(${r.status ?? r.signal})`;
  return false;
}

let bad = 0;
for (const shape of names.length ? names : Object.keys(shapes)) {
  slow = false; failure = "";
  let lo = 0, hi = 0, n = 250;
  while (n <= limit) {
    if (passes(shape, n)) { lo = n; n *= 2; if (slow) break; } else { hi = n; break; }
  }
  if (hi) {
    while (hi - lo > Math.max(1, lo / 50)) {
      const mid = Math.floor((lo + hi) / 2);
      if (passes(shape, mid)) lo = mid; else hi = mid;
    }
  }
  if (hi && failure !== "too_deep") bad++;
  console.log(`${shape.padEnd(14)} ok ${String(lo).padStart(7)}  fails ${String(hi || "-").padStart(7)} ${hi ? failure : slow ? "(stopped: slow)" : ""}`);
}
process.exit(bad ? 1 : 0);
