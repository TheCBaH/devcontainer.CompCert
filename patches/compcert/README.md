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

The tests build and proof-check isolated compilers, compile FP32 kernels and
high-pressure spills, link a freestanding GCC harness with matching integer
ABI, and execute with QEMU's D extension disabled. A separate D instruction
must run with D enabled and trap with SIGILL when disabled. Negative compiler
tests cover FP64, implicit promotion, float interfaces, varargs, direct and
indirect calls, inline assembly, and RV32 float-to-int64 widening. A final
configuration check compiles and executes the original D ABI and double
arithmetic.

The first milestone does not add these experimental profiles to the published
six-target artifact matrix. No release or downstream pin update is needed to
run the experiment.
