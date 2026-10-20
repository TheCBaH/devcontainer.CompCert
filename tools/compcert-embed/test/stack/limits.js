// Check the published input limits (limits.txt) against a bundle:
//   node limits.js [--stack KB]
// Environment: CC_BUNDLE as for sweep.js; LIMITS_FULL=1 includes the slow
// shapes; LIMITS_BEYOND (default 3) is the factor by which each shape is
// pushed past its limit to check that the build still answers cleanly.
// Exits 1 on a regression.
const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");
const full = process.env.LIMITS_FULL === "1";
const si = process.argv.indexOf("--stack");
const stack = si > 0 ? +process.argv[si + 1] : 984;
const beyond = +(process.env.LIMITS_BEYOND || 3);

let bad = 0;
for (const line of fs.readFileSync(path.join(__dirname, "limits.txt"), "utf8").split("\n")) {
  if (!line.trim() || line.startsWith("#")) continue;
  const [shape, n, ...flags] = line.trim().split(/\s+/);
  const slow = flags.includes("slow");
  if (slow && !full) { console.log(`${shape.padEnd(14)} skipped (slow)`); continue; }
  // Each compile runs in a fresh process, so the engine is cold, as in a new Worker.
  const run = (k) => {
    const r = spawnSync(process.execPath, [`--stack-size=${stack}`, path.join(__dirname, "try.js"), shape, String(k)], {
      encoding: "utf8", env: process.env,
    });
    const [kind, secs] = (r.stdout || "").trim().split(" ");
    return { kind: kind || `crash(${r.status ?? r.signal})`, secs };
  };
  const at = run(+n);
  let msg = `${shape.padEnd(14)} ${String(n).padStart(6)}: ${at.kind} (${at.secs}s)`;
  if (at.kind !== "ok") { msg += "  REGRESSION"; bad++; }
  if (flags.includes("beyond") && (!slow || full)) {
    const far = run(Math.min(+n * beyond, 400000));
    msg += `; ${beyond}x: ${far.kind} (${far.secs}s)`;
    if (!["ok", "diagnostics", "too_deep"].includes(far.kind)) { msg += "  BAD ANSWER"; bad++; }
  }
  console.log(msg);
}
process.exit(bad ? 1 : 0);
