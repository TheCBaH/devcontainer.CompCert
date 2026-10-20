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

Melange (`COMPCERT_MELANGE=true dune build ./melange/bind`, needs dune 3.15 and
`melange`; `melange/bundle.sh out.mjs` makes one minified ES module with
esbuild) exports `compile(source, options)`, `version` and `target` with the
same result objects. It compiles every test program, but does not yet give the
jsoo build's byte-for-byte output (hash order), and it has lower stack limits,
listed in `test/stack/limits-melange.txt` (`node test/stack/limits.js --limits
test/stack/limits-melange.txt`): for example 450 for `a + 1 + 1 + ...`, 870
nested blocks, and 5,000 statements in one function.

## Input

The input must be preprocessed C: no `#include`, `#define` or conditionals.
Line markers are accepted. The generated assembly is byte-identical to
`ccomp -S` on the same input, apart from the first two header lines.

## Limits

JavaScript engines give a fixed stack (V8: about 984 KB). `test/stack/limits.txt`
lists, per input shape, the size the build is tested to compile in a freshly
started process at that stack size; larger inputs may still compile, and
the ones that fail by recursion depth answer `too_deep`. Sizes by memory
(`strings`, `globals`, ...) end in the engine's out-of-memory error instead.

| Shape | Size |
|---|---|
| global definitions | 50,000 |
| functions | 20,000 |
| statements in one function (takes minutes: CompCert's allocator is quadratic) | 50,000 |
| string literals / initializer elements | 50,000 |
| nested parentheses | 50,000 |
| `a + 1 + 1 + ...` chain | 3,100 |
| `(1 + (1 + ...))` nesting | 2,900 |
| `if / else if` chain | 2,500 |
| nested blocks | 1,850 |
| `case` labels in one switch | 1,490 |
| arguments in one call | 1,740 |
| nested `if` | 980 |
| struct members | 5,900 |
| local variables in one function | 5,000 |

Also: objects of 2 GiB or more are rejected (`sizeof ... overflows`), where a
native build accepts them, because JavaScript builds have 32-bit `int`.

To re-check: `CC_BUNDLE=$PWD/_build/default/jsoo/compcert_jsoo.bc.js node test/stack/limits.js`
(`LIMITS_FULL=1` includes the slow shapes).

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
