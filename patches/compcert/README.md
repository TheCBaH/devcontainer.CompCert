# CompCert source patches

These patches modify the pinned upstream submodule and are covered by
[CompCert's license](../../modules/CompCert/LICENSE). The extractor's MIT
license does not cover CompCert-derived code.

`tools/compcert-prepare-source.sh` applies them idempotently and refuses an
unexpected upstream revision. Normal builds, cross-smokes and exports use
this preparation step. Export manifests identify every applied patch by hash.

`0001-riscv-fp32-kernels.patch` adds experimental `rv32-fp32-kernel` and
`rv64-fp32-kernel` configure targets. Existing targets retain their D ABI.
The new targets are freestanding, with integer ILP32/LP64 interfaces and
native F instructions. Only leaf functions with non-variadic integer/pointer
parameters and results are accepted. Float data is passed through pointers.
FP64, opaque 64-bit FP transport, calls, tail calls and inline assembly are
rejected after builtin expansion. Optimizations can remove unsupported source
operations; restrictions apply to retained code. Use explicit `f` suffixes
for float constants.

The allocator uses only FP caller-save registers; float spills remain 32 bits.
Generic FP moves print as `fmv.s` and RV32 composite copies use integer
instructions. The post-expansion checker enumerates all instruction
constructors, allowing FP32 producers and transport while rejecting FP64.
Ordinary C type sizes and double semantics remain unchanged.

This is an experimental compiler restriction, not a new end-to-end formal
correctness result. Existing Rocq proofs are rebuilt and checked, but the
FP32 restriction and narrower printing are implemented in the unverified
assembly expansion/printing stage. A proof connecting that restriction to
the F-only machine remains future work, as do general calls/FP interfaces
and software double arithmetic.

Run inside the devcontainer:

```sh
make compcert-fp32-test RISCV_BITS=32
make compcert-fp32-test RISCV_BITS=64
```

The test retains its compiler and FP32 configuration. To compile another
RV32 kernel in the same devcontainer:

```sh
.fp32-work/rv32/compiler/ccomp -conf .fp32-work/rv32/fp32.ini \
  -fno-pie -S kernel.c
```

The caller, startup code and linker must use a matching integer ABI and ISA.
These kernels need no CompCert runtime, but the surrounding program must
provide the target's startup and execution environment.

The tests build and proof-check isolated compilers, rebuild their extraction
archives in fresh source checkouts, compile FP32 kernels and high-pressure
spills with those rebuilt compilers, link a GCC harness with matching integer
ABI, and execute with QEMU's D extension disabled. A separate D instruction
must run with D enabled and trap with SIGILL when disabled. Negative compiler
tests cover FP64, implicit promotion, float interfaces, varargs, direct and
indirect calls, inline assembly, and RV32 float-to-int64 widening. A final
configuration check compiles and executes the original D ABI and double
arithmetic.

Both FP32 jobs also examine every C translation unit in the pinned upstream
small-test suite, including its generated ABI cases. `upstream/results.tsv`
under each `.fp32-work/rv<bits>/` records compilation and assembly passes,
FP32-profile rejections, and cases rejected by the ordinary RISC-V compiler.
`test/riscv-fp32/upstream-rv<bits>.tsv` is the reviewed acceptance baseline;
CI fails on changes to it, unexpected compiler failures, assembly failures,
or execution failures. Baseline and profile rejections are not test passes.

At the pinned test revision, RV32 and RV64 have the same acceptance:

| Suite | C units | Compile and assemble | Profile rejected | Baseline rejected |
| --- | ---: | ---: | ---: | ---: |
| c | 24 | 0 | 24 | 0 |
| regression | 108 | 12 | 91 | 5 |
| compression | 12 | 1 | 11 | 0 |
| raytracer | 14 | 0 | 14 | 0 |
| spass | 51 | 1 | 50 | 0 |
| abi, including generated cases | 8 | 0 | 8 | 0 |
| pic | 4 | 1 | 3 | 0 |
| export C inputs | 6 | 4 | 2 | 0 |
| Total | 227 | 19 | 203 | 5 |

The first profile diagnostic reports calls in 172 cases, FP/variadic interfaces
in 19, FP64 or unsupported instructions in 11, and inline assembly in one.
The five baseline rejections are `funct1.c` (an upstream negative test) and
the four builtin tests for other architectures. Some accepted units only
define data; compilation acceptance does not imply a runnable program.

The census preprocesses with the ordinary D-ABI configuration and CompCert's
headers, since the installed glibc headers do not provide the integer ABI.
The same preprocessed C is compiled by both configurations. This checks
backend acceptance; it does not establish F-only libc compatibility.

Eight accepted upstream leaf sources run with new integer-ABI harnesses and
D disabled: `regression/{expr3,expr4,extern1,ptrs1,struct9,types1}.c` and
`export/{bitfields,issue216}.c`. Upstream source files are unchanged.
`upstream/execution.tsv` records these results separately. These harnesses
do not constitute a run of the complete upstream executables: programs
requiring calls, FP-valued interfaces, doubles or libc remain unsupported by
the experimental profile. The existing kernel fixtures exercise native FP32.

The first milestone does not add these experimental profiles to the published
six-target artifact matrix. No release or downstream pin update is needed to
run the experiment.
