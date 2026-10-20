# CompCert as an embeddable library

This package is one CompCert target (see `MANIFEST`) built to run inside a
program, including a JavaScript engine: preprocessed C source text in, assembly
text or CompCert's diagnostics out. No file system, no subprocess. It contains
sources only; build it with dune.

CompCert is not free software (non-commercial use only, see `LICENSE`).

## Contents

| Path | What |
|---|---|
| `src/` | CompCert's extracted OCaml, with `patches/embed.patch` applied (one `open` per file, injected `embed_*.ml`) and the stack patches below |
| `list/` | `Embed_list`: constant-stack versions of the stdlib list functions, opened into every module of `src/` |
| `api/` | `Compcert_js`, the backend-neutral compile function |
| `jsoo/` | js_of_ocaml binding, `compcert_jsoo.bc.js`, and `worker.js` |
| `melange/`, `shims/`, `vendor/menhirLib/` | the Melange build: binding, pure-OCaml `Str` and `Unix`, the menhirLib of the generating menhir |
| `test/` | native tests, the differential driver, the stack tests |
| `patches/` | every patch applied to the extracted sources |
| `MANIFEST` | CompCert revision, tool versions, hash of every file |

## API

```ocaml
Compcert_js.compile : options -> string -> (string, error) result
```

`options` selects the optimization level, struct passing, PIE, `-g`, and a
whitelist of code-generation flags (`-fpacked-structs`,
`-funstructured-switch`, `-finline-asm` and their negations). `compile` never
raises. Errors are `Diagnostics` (CompCert's own text, as `ccomp` prints it),
`Too_deep` (the stack ran out), `Unsupported` and `Internal`. After `Too_deep`,
start a fresh instance (a new Worker): CompCert's state may be partial.

Compiles must not overlap: CompCert keeps its state in globals, and every call
resets it first. The assembly header names the unit as `ccomp -S <name>`.

JavaScript (`dune build --profile release ./jsoo`, needs `js_of_ocaml`):

```js
const r = CompCert.compile(source, { name: "gen.c", opt: "O2" });
// { ok: true, asm, diagnostics } | { ok: false, kind, message }
```

`kind` is `diagnostics`, `too_deep`, `unsupported`, `internal` or `options`.
`jsoo/worker.js` wraps the same call for a Web Worker.

Melange (`COMPCERT_MELANGE=true dune build ./melange/bind`, needs dune 3.15, `melange`
and `ppxlib`; `melange/bundle.sh out.mjs` makes one minified ES module with
esbuild) exports `compile(source, options)`, `version` and `target` with the
same result objects. Its output is byte-identical to the native and js_of_ocaml builds
(`melange/evalorder` restores the right-to-left evaluation order of arguments
that ocamlopt uses and JavaScript does not). It has lower stack limits,
listed above (`node test/stack/limits.js --limits test/stack/limits-melange.txt`).

`debug: true` (`-g`) emits the DWARF sections as `ccomp -S -g` does, with
`DW_AT_comp_dir` taken from the `dir` option ("/" by default; `ccomp` uses its
working directory). The one other difference is that `ccomp -S -g` copies each C source line into a `//` comment
next to its code; that needs the C files, and no files are read here.

## Input

The input must be preprocessed C: no `#include`, `#define` or conditionals.
Line markers are accepted. The generated assembly is byte-identical to
`ccomp -S` on the same input, apart from the first two header lines.

## Limits

JavaScript engines give a fixed stack, and a Worker gets less than the main
thread (Chromium: about half of V8's 984 KB in Node). `test/stack/limits.txt`
lists, per input shape, the size the js_of_ocaml build is tested to compile in a
freshly started Chromium Worker, the smallest stack of the supported engines;
Firefox and WebKit allow more. Larger inputs may still compile, and the ones
that fail by recursion depth answer `too_deep`. Sizes by memory end in the
engine's out-of-memory error instead.

| Shape | js_of_ocaml | Melange |
|---|---|---|
| global definitions | 50,000 | 50,000 |
| functions | 20,000 | 20,000 |
| statements in one function (minutes: CompCert's allocator is quadratic) | 50,000 | 5,000 |
| string literals / initializer elements | 50,000 | 14,000 |
| nested parentheses | 50,000 | 50,000 |
| `a + 1 + 1 + ...` chain | 1,400 | 150 |
| `(1 + (1 + ...))` nesting | 1,400 | 150 |
| `if / else if` chain | 920 | 420 |
| nested blocks | 870 | 350 |
| `case` labels in one switch | 640 | 335 |
| arguments in one call | 870 | 500 |
| nested `if` | 470 | 180 |
| struct members | 2,800 | 2,580 |
| local variables in one function | 2,450 | 2,450 |

The Melange column is `test/stack/limits-melange.txt`. Node's main thread
allows roughly twice the recursion shapes (for example `a + 1 + 1 + ...`: 3,500
for js_of_ocaml).

Also: objects of 2 GiB or more are rejected (`sizeof ... overflows`), where a
native build accepts them, because JavaScript builds have 32-bit `int`.

To re-check in Node: `CC_BUNDLE=$PWD/_build/default/jsoo/compcert_jsoo.bc.js node test/stack/limits.js`
(`LIMITS_FULL=1` includes the slow shapes); in browsers, `test/browser/run.mjs --limits`.

## Changes to CompCert's code

Compared with the extraction in `compcert-export-<target>`:

- `patches/embed.patch`, the injected `embed_*.ml`: in-memory input and output,
  the configuration baked in, a fixed command line in the header.
- `Embed_list` through `-open`: `@`, `List.map`, `mapi`, `map2`, `append`,
  `flatten`, `concat`, `fold_right`, `split`, `combine`, with the same results,
  evaluation order and exceptions, in constant stack.
- `patches/stack.patch`: the same kind of rewrite in hand-written code
  (`Elab.elab_block_body`, `Cflow.outcomes_block`, the `mmap` helpers, and
  `Unblock`, which also rebuilds long statement sequences as balanced trees).
  It also rewrites Rocq-extracted list functions (`AST.transf_globdefs`,
  `Errors.mmap`, `List0.rev`/`fold_right`/`filter`/`remove`, `ListDef.map`,
  `Datatypes.app`) as accumulate-and-reverse loops. **These are hand-written
  replacements for extracted, proved code.** They are mechanical, keep the
  evaluation order and the first error, and `test/stack/unit.ml` checks each
  against the original on random inputs, failures included.
- `patches/stack-<arch>.patch`: the same for `Asmgen.transl_code_rec`.

The compiled output is unchanged: `test/native/check.sh` compares every file of
CompCert's test programs with `ccomp -S`.
