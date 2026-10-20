// Real-browser tests of the JavaScript builds:
//   node run.mjs --jsoo <compcert_jsoo.bc.js> --melange <compcert_melange.min.mjs>
//        --corpus <dir> --expected <dir> --gen <test/stack/gen.js> [options]
//
// Each browser starts a Worker per backend, compiles a subset of the corpus and
// compares with the native embed build's output (lines 3 on), measures load,
// first and steady-state compile times and heap growth over many compiles, and
// bisects the largest input of each recursion shape that still compiles.
// Options: --browsers chromium,firefox,webkit  --subset 32  --repeats 200
//          --sweep (the stack sweep)  --limits (the published limits)
//          --shapes a,b,c (shapes for the sweep)  --out report.json
import { createServer } from "node:http";
import { readFileSync, readdirSync, statSync, existsSync, mkdtempSync, copyFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname, extname } from "node:path";
import { fileURLToPath } from "node:url";
import playwright from "playwright";

const here = dirname(fileURLToPath(import.meta.url));
const args = Object.fromEntries(
  process.argv.slice(2).reduce((acc, a, i, all) => (a.startsWith("--") ? [...acc, [a.slice(2), all[i + 1] && !all[i + 1].startsWith("--") ? all[i + 1] : true]] : acc), []),
);
const need = (k) => args[k] || (console.error(`missing --${k}`), process.exit(2));
const corpus = need("corpus"), expected = need("expected"), gen = need("gen");
const browsers = (args.browsers || "chromium,firefox").split(",");
const subsetSize = +(args.subset || 32), repeats = +(args.repeats || 200);

// What the page serves: the workers, the bundles, gen.js and the limits.
const stage = mkdtempSync(join(tmpdir(), "compcert-browser-"));
for (const f of ["worker-jsoo.js", "worker-mel.mjs", "harness.js"]) copyFileSync(join(here, f), join(stage, f));
copyFileSync(gen, join(stage, "gen.js"));
if (args.jsoo) copyFileSync(args.jsoo, join(stage, "compcert_jsoo.bc.js"));
if (args.melange) copyFileSync(args.melange, join(stage, "compcert_melange.min.mjs"));
writeFileSync(join(stage, "index.html"), '<!doctype html><meta charset="utf-8"><script src="harness.js"></script>');

const mime = { ".js": "text/javascript", ".mjs": "text/javascript", ".html": "text/html" };
const server = createServer((req, res) => {
  const url = decodeURIComponent(req.url.split("?")[0]);
  let file;
  if (url.startsWith("/corpus/")) file = join(corpus, url.slice(8));
  else if (url.startsWith("/expected/")) file = join(expected, url.slice(10));
  else file = join(stage, url === "/" ? "index.html" : url.slice(1));
  if (!file.startsWith(corpus) && !file.startsWith(expected) && !file.startsWith(stage)) { res.writeHead(403); return res.end(); }
  if (!existsSync(file) || !statSync(file).isFile()) { res.writeHead(404); return res.end("not found"); }
  res.writeHead(200, { "content-type": mime[extname(file)] || "text/plain", "cache-control": "no-store" });
  res.end(readFileSync(file));
});
await new Promise((r) => server.listen(0, "127.0.0.1", r));
const base = `http://127.0.0.1:${server.address().port}/`;

// The subset: the corpus files that compile, the largest one first, then evenly spaced.
const ok = readFileSync(join(corpus, "ok.txt"), "utf8").split("\n").filter(Boolean);
const bad = readFileSync(join(corpus, "expected-fail.txt"), "utf8").split("\n").filter(Boolean);
// The name a file is compiled under is the path the native results were made with
// (diagnostics quote it), which is not where the corpus is served from in CI.
const nativeRoot = args["corpus-path"] || corpus;
const all = [...ok, ...bad.slice(0, 3)].map((name) => ({ name, file: join(nativeRoot, name + ".i"), size: statSync(join(corpus, name + ".i")).size }));
all.sort((a, b) => b.size - a.size);
const step = Math.max(1, Math.floor(all.length / subsetSize));
const manifest = all.filter((_, i) => i === 0 || i % step === 0).slice(0, subsetSize);
const medium = all[Math.floor(all.length / 4)];

const backends = [args.jsoo && "jsoo", args.melange && "mel"].filter(Boolean);
const shapesFor = { jsoo: args.shapes ? args.shapes.split(",") : ["exprchain", "addnest", "blocknest", "ifnest", "elseif", "switchcases", "callargs", "structfields", "stringstmts", "localvars"] };
shapesFor.mel = shapesFor.jsoo;

const report = {};
let failed = false;
for (const name of browsers) {
  const browser = await playwright[name].launch({ args: name === "chromium" ? ["--enable-precise-memory-info", "--js-flags=--expose-gc"] : [] });
  report[name] = { version: browser.version() };
  for (const backend of backends) {
    const page = await browser.newPage();
    page.on("pageerror", (e) => console.error(`[${name}/${backend}] page error: ${e.message}`));
    await page.goto(base);
    await page.waitForFunction(() => window.harness);
    const entry = (report[name][backend] = {});
    console.error(`[${name}/${backend}] corpus subset (${manifest.length} files)`);
    entry.subset = await page.evaluate(([b, m]) => window.harness.runSubset(b, m), [backend, manifest]);
    if (entry.subset.diff.length) failed = true;
    console.error(`[${name}/${backend}] timing and heap (${medium.name}, ${repeats} compiles)`);
    entry.timing = await page.evaluate(([b, f, r]) => window.harness.measure(b, f, r), [backend, medium, repeats]);
    entry.main = await page.evaluate(([b, f, r]) => window.harness.measureMain(b, f, r), [backend, medium, repeats]);
    if (args.limits) {
      console.error(`[${name}/${backend}] published limits`);
      const file = join(here, "..", "stack", backend === "mel" ? "limits-melange.txt" : "limits.txt");
      entry.published = await page.evaluate(([b, t]) => window.harness.checkLimits(b, t, 120000), [backend, readFileSync(file, "utf8")]);
    }
    if (args.sweep) {
      console.error(`[${name}/${backend}] stack sweep`);
      entry.limits = await page.evaluate(([b, s]) => window.harness.sweep(b, s, 20000, 60000), [backend, shapesFor[backend]]);
    }
    await page.close();
  }
  await browser.close();
}
server.close();
const json = JSON.stringify(report, (k, v) => (k === "times" ? undefined : v), 2);
if (args.out) writeFileSync(args.out, json);
console.log(json);
process.exit(failed ? 1 : 0);
