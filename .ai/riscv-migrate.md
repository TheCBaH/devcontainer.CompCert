# Adding CompCert's RISC-V runtime to the gas-xref frontier corpus

Written 2026-09-05. Baseline: `b659f3e` plus the uncommitted `.ai/` review
edits. Status: executed 2026-09-05.

## 1. What this closes

`gas_xref_cmd.ml`'s `frontier_sources` builds each target's runtime group by
looking for `modules/CompCert/runtime/<target>`. CompCert's tree is
arch-named rather than target-named, so both RISC-V profiles live in
`runtime/riscV` and neither `runtime/riscv32` nor `runtime/riscv64` exists.
Both are silently skipped, and the runtime group covers four targets instead
of six.

The omission was deliberate: the OCaml port reproduced the original shell
script's `[ -d … ] || continue` behavior on purpose, because widening it
would have changed the recorded corpus during a port whose whole point was
fidelity. That reason has expired. The port is established, the corpus is
regenerable evidence rather than a fixed baseline, and
`tools-gasxref-diff` already gates it for byte-identical reproduction.

What makes this worth doing is not the evidence it adds — that is small, see
section 6 — but the explanation it deletes. The same fact is currently
written out in five places:

| Location | Form |
|---|---|
| `asm/tools/lib/gas_xref_cmd.ml:11-15` | The "silently covers only FOUR targets" block comment |
| `asm/tools/lib/gas_xref_cmd.ml:45-47` | The `is_dir` comment, "a missing directory is the NORMAL case here" |
| `asm/test/cram/gas_frontier.t:7-8` | Prose parenthetical, "plus, for RISC-V, the one fixture control …" |
| `asm/docs/corpus.md:1364-1366`, `1374-1376`, `1741-1742` | Three restatements, one per follow-up entry |
| `.ai/isa-consumption-plan.md` §2.4 | The out-of-scope paragraph and its sizing |

This is also the second half of a migration already begun. `corpus.md:1373`
records **"The Helper half is now done"** — `asm/helpers/riscv32.s` and
`riscv64.s` were added in an earlier pass, which is why RISC-V has two
frontier cases today rather than one. Runtime is what that entry left open.

## 2. Preconditions

Check all four before starting; each failure mode below produces a wrong
corpus rather than an error.

```sh
# 1. Submodule initialized - otherwise every runtime case is silently dropped
#    and the regen writes a corpus missing all 39 existing runtime cases
#    (arm 17, x86_32 17, x86_64 4, aarch64 1).
test -f modules/CompCert/runtime/riscV/vararg.S && echo ok

# 2. Both RISC-V assemblers reachable. riscv32 is NOT on the default PATH;
#    Gnu_tools finds it through Target.toolprefix.
riscv64-linux-gnu-as --version | head -1
/usr/local/riscv32-linux-gnu-toolchain/bin/riscv32-linux-gnu-as --version | head -1

# 3. Tool versions match what the corpus was recorded with, or the regen
#    churns unrelated cases. Expect 2.44 everywhere except riscv32 (2.43.1).
cat asm/fixtures/gas-xref/tool-versions.txt

# 4. Corpus clean, so the diff you review afterwards is only this change.
git status --porcelain -- asm/fixtures/gas-xref
```

At the time of writing all four hold: versions match `tool-versions.txt`
exactly, so the regen diff will be confined to the two new cases.

## 3. Code change

Two edits in `asm/tools/lib/gas_xref_cmd.ml`.

**3.1 Map target to runtime directory.** `frontier_sources` currently uses
`Target.to_string target` for both the fixture/helper paths and the runtime
path. The first two are genuinely target-named; the third is not. Add a
separate mapping above `frontier_sources` rather than overloading
`Target.to_string`:

```ocaml
(* CompCert's runtime tree is arch-named, not target-named: both RISC-V
   profiles share runtime/riscV, and it is the MODEL_ define below - not the
   directory - that selects the 32- or 64-bit half of vararg.S. Every other
   target's arch name and target name coincide. *)
let runtime_dir = function
  | Target.Riscv32 | Target.Riscv64 -> "riscV"
  | t -> Target.to_string t
```

and change the `dir` binding inside `frontier_sources` from
`"modules/CompCert/runtime/" ^ t` to
`"modules/CompCert/runtime/" ^ runtime_dir target`. Leave the `fixed` list's
use of `t` alone — `asm/fixtures/compcert-3.17/return42/<t>/` and
`asm/helpers/<t>.s` really are target-named.

**3.2 Supply the RISC-V preprocessor defines.** `runtime_defines` currently
returns `[]` for both RISC-V profiles, which would leave `MODEL_` undefined
and trip `sysdeps.h`'s `#error "Wrong MODEL"`. The values come from
CompCert's own `configure:199-201` (`arch="riscV"; model="32"|"64";
endianness="little"`) and `configure:413` (`abi="standard"`):

```ocaml
  | Target.Riscv32 -> [ "-DMODEL_32"; "-DABI_standard"; "-DENDIANNESS_little"; "-DSYS_linux" ]
  | Target.Riscv64 -> [ "-DMODEL_64"; "-DABI_standard"; "-DENDIANNESS_little"; "-DSYS_linux" ]
```

replacing the single `| Target.Riscv32 | Target.Riscv64 -> []` arm.

**3.3 Rewrite the two stale comments.** The block comment at lines 11-15
should now say the runtime group covers all six targets and that RISC-V
reaches `riscV` through `runtime_dir`. The `is_dir` comment at 45-47 claims
a missing directory is the normal case; after this change every target maps
to a directory that exists, so keep the guard — it still protects against an
uninitialized submodule — but say that is what it is now for.

## 4. Regenerate and verify

```sh
make asm-gas-xref-regen          # deletes and rebuilds the corpus root
git status --porcelain -- asm/fixtures/gas-xref   # review before promoting
make tools-gasxref-diff          # regen must now reproduce byte-identically
make asm-test                    # includes asm-gas-xref-check
```

`asm-gas-xref-regen` needs both RISC-V toolchains and rebuilds all six
targets, which is why it is off the `asm-ci` path. `tools-gasxref-diff` is
the determinism gate: it regenerates again and fails if anything moves.

## 5. Expected diff

**Corpus.** Two new case directories, `frontier/riscv32/runtime-vararg/` and
`frontier/riscv64/runtime-vararg/`, five files each (`gas.txt`, `input.s`,
`objdump.txt`, `origin.txt`, `text.hex`) since GAS assembles both — verified
in section 6. Nothing else should move.

| | Before | After |
|---|---:|---:|
| Tracked files under `asm/fixtures/gas-xref` | 473 | 483 |
| `manifest.txt` lines (2 header + one sha per file) | 474 | 484 |
| `frontier/riscv32`, `frontier/riscv64` cases | 2 each | 3 each |

Three cases per RISC-V profile matches aarch64, whose runtime is also just
`vararg`.

**Expect tests.** Both will need promoting, and neither is optional:

- `asm/test/xref/test_xref.ml`'s "frontier corpus" block lists every
  agreement and ends with a summary line, currently
  `29 agree, 0 differ, 22 beyond M1, 0 not assembled by GNU as`. The two new
  cases land in `agree` or in `beyond M1` depending on whether our assembler
  accepts them; either is a valid recorded outcome. A `DIFFER` is a hard
  failure — investigate rather than promote.
- `asm/test/cram/gas_frontier.t` carries the per-file detail plus prose at
  lines 7-8 that states the RISC-V exclusion. Update the prose by hand; the
  transcript itself promotes.

Promote with `cd asm && opam exec -- dune build @runtest --auto-promote`, or
per test as in CLAUDE.md, and read the promoted diff rather than accepting
it blind.

**Documentation.** Remove the explanation everywhere section 1 lists it:
`corpus.md`'s three restatements become a single closing note that the
Helper *and* Runtime halves are now done; `.ai/isa-consumption-plan.md` §2.4
loses the out-of-scope paragraph in favor of one sentence saying the runtime
group covers all six targets; `.ai/isa-consumption-tracker.md`'s evidence
row for this sizing becomes a row recording that it was closed.

**One stale count to fix while here.** `Makefile:631` describes the corpus as
"463 committed files". It is 473 today — the comment went stale when the
helper half of this same migration landed. Update it to the new total rather
than leaving a second drifting number behind.

## 6. What the evidence is actually worth

Small, and the instructions should not oversell it. CompCert's entire RISC-V
runtime is one 90-line file. Its instruction content after preprocessing is
`lw`/`ld`/`sw`/`sd` (through `sysdeps.h`'s `lptr`/`sptr` macros), `addi`,
`and` with a negative immediate, `fld`, `jr` and `j` — base integer plus one
D-extension load. All of it is covered far more thoroughly, with real operand
variation, by the differential work in
[isa-consumption-plan.md](isa-consumption-plan.md) S3 and GEN-03.

The preprocess-and-assemble path was verified directly, running exactly what
`Gnu_tools.preprocess` and `Gnu_tools.try_assemble` run, with each profile's
real `as_args` from `asm/tools/lib/target.ml:145-180`:

```sh
riscv32-linux-gnu-gcc -E -P -DMODEL_32 -DABI_standard -DENDIANNESS_little \
  -DSYS_linux -I modules/CompCert/runtime/riscV \
  modules/CompCert/runtime/riscV/vararg.S > rv32.s
riscv32-linux-gnu-as -march=rv32imafd -mabi=ilp32d -mno-relax -o rv32.o rv32.s
# and the riscv64 equivalent with -DMODEL_64 / -march=rv64imafd -mabi=lp64d
```

Both preprocessed and assembled clean: `sysdeps.h` resolved, `MODEL_32`
selected `lw`/`sw` and `MODEL_64` selected `ld`/`sd`, and no `#error "Wrong
MODEL"` fired. So the corpus outcome is known in advance to be a recorded
assembly, not a GAS rejection.

## 7. Scope and sequencing

Land this as its own commit: a tooling change plus a corpus diff, reviewed on
its own merits. Do not fold it into the ISA consumption plan's S1, which is a
Python capture fix touching entirely different files. It is not a dependency
of S1 or of anything downstream of it — the generated-case corpus in that
plan is deliberately separate from `gas-xref`'s.

## 8. Rollback

Everything here is in git and nothing is published outside the tree:

```sh
git checkout -- asm/fixtures/gas-xref asm/tools/lib/gas_xref_cmd.ml \
  asm/test/xref/test_xref.ml asm/test/cram/gas_frontier.t
```

then re-run `make tools-gasxref-diff` to confirm the restored corpus still
reproduces.
