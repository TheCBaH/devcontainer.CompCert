# CompCert source patches

These patches modify the pinned upstream submodule and are covered by
[CompCert's license](../../modules/CompCert/LICENSE). The extractor's MIT
license does not cover CompCert-derived code.

`tools/compcert-prepare-source.sh` applies them idempotently and refuses an
unexpected upstream revision. Normal builds, cross-smokes and exports use
this preparation step. Export manifests identify every applied patch by hash.

`0001-riscv-fp32-kernels.patch` adds these experimental freestanding targets.
Existing targets retain their D ABI.

| Targets | GNU ABI | Supported interfaces |
| --- | --- | --- |
| `rv32-fp32-kernel`, `rv64-fp32-kernel` | ILP32, LP64 | Leaf functions with integer/pointer parameters and results |
| `rv32-fp32`, `rv64-fp32` | ILP32F, LP64F | Scalar integer/pointer/FP32 parameters and results; direct, indirect and tail calls |

Both profiles use native F instructions and reject FP64, opaque 64-bit FP
transport and inline assembly after builtin expansion. The call-capable
profiles support scalar integer/pointer variadics and reject aggregate-by-value
definitions and calls. Structs accessed through pointers remain supported. Optimizations
can remove unsupported source operations; instruction restrictions apply to
retained code. Use explicit `f` suffixes for float constants.

The allocator uses only FP caller-save registers; float spills remain 32 bits.
Generic FP moves print as `fmv.s` and RV32 composite copies use integer
instructions. The post-expansion checker enumerates all instruction
constructors, allowing FP32 producers and transport while rejecting FP64.
Ordinary C type sizes and double semantics remain unchanged.

This is an experimental compiler restriction, not a new end-to-end formal
correctness result. Existing Rocq proofs are rebuilt and checked, but the
FP32 restriction and narrower printing are implemented in the unverified
assembly expansion/printing stage. A proof connecting that restriction to
the F-only machine remains future work, as do aggregate-by-value ABI support,
floating variadic arguments and software double arithmetic.

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

For the call-capable RV32 profile, use the same compiler with
`-conf .fp32-work/rv32/calls/calls.ini`, and compile the caller and runtime
with `-march=rv32imf_zicsr -mabi=ilp32f`. RV64 uses `rv64imf_zicsr` and
`lp64f`. Named scalar floats use `fa0`–`fa7`, with overflow in integer
registers or on the stack; scalar float results use `fa0`. The allocator
currently avoids `fs0`–`fs11` and spills live FP32 values across calls.

The [RISC-V psABI](https://riscv-non-isa.github.io/riscv-elf-psabi-doc/)
defines the F ABIs with ABI_FLEN=32. `double` remains 64 bits, and variadic
`float` arguments are promoted to `double` and passed using integer rules.
RV32 uses aligned register pairs; RV64 uses one integer register. Integer/pointer
variadic calls, definitions and stdarg operations are supported. Floating
variadic arguments remain rejected. Full support
requires software-double lowering and a matching runtime, which this patch
does not supply. F-ABI and D-ABI objects cannot be linked together normally;
all dependencies must also avoid D instructions. Selecting an F ABI alone
does not restrict a library's instruction set.

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

Integer/pointer varargs tests exercise GCC/CompCert callers and callees in both
directions, integer promotions, 64-bit aligned pairs, register/stack overflow,
named FP32 parameters, va_copy and va_list forwarding. They link the maintained
integer varargs helpers assembled for the F ABI, without the D-only float64
helper. Aggregate va_arg remains rejected.

The call tests compile separate CompCert and GCC translation units and
execute with D disabled. They cover FP32 arguments/results, mixed arguments,
18-float overflow into integer registers and the stack, signed zero and NaN
payload transport, direct/indirect/tail calls, recursion, 40 values live
across a deliberately clobbering callee, stack alignment and `fs0`–`fs11`
preservation. Negative cases cover double calls, promotions, floating variadics and
aggregate interfaces. A linker probe rejects F/D ABI mixing, and GCC's
varargs reference must use `__extendsfdf2` without D.

Both FP32 jobs also examine every C translation unit in the pinned upstream
small-test suite, including its generated ABI cases. `upstream/results.tsv`
under each `.fp32-work/rv<bits>/` records compilation and assembly passes,
FP32-profile rejections, and cases rejected by the ordinary RISC-V compiler.
The call profile has a second report in `calls/upstream/results.tsv`.
`test/riscv-fp32/upstream-rv<bits>.tsv` and `upstream-calls-rv<bits>.tsv`
are the reviewed acceptance baselines;
CI fails on changes to it, unexpected compiler failures, assembly failures,
or execution failures. Baseline and profile rejections are not test passes.

At the pinned test revision, RV32 and RV64 have the same acceptance:

| Suite | C units | Kernel accepted | Calls accepted | Baseline rejected |
| --- | ---: | ---: | ---: | ---: |
| c | 24 | 0 | 12 | 0 |
| regression | 108 | 12 | 60 | 5 |
| compression | 12 | 1 | 12 | 0 |
| raytracer | 14 | 0 | 3 | 0 |
| spass | 51 | 1 | 47 | 0 |
| abi, including generated cases | 8 | 0 | 2 | 0 |
| pic | 4 | 1 | 4 | 0 |
| export C inputs | 6 | 4 | 6 | 0 |
| Total | 227 | 19 | 146 | 5 |

The kernel profile's first diagnostic reports calls in 172 cases, FP/variadic interfaces
in 19, FP64 or unsupported instructions in 11, and inline assembly in one.
The five baseline rejections are `funct1.c` (an upstream negative test) and
the four builtin tests for other architectures. Some accepted units only
define data; compilation acceptance does not imply a runnable program.

The census preprocesses with the ordinary D-ABI configuration and CompCert's
headers, since the installed glibc headers do not provide the F-only ABIs.
The same preprocessed C is compiled by both configurations. This checks
backend acceptance; it does not establish F-only libc compatibility.

Eight accepted upstream leaf sources run with harnesses using the selected ABI and
D disabled: `regression/{expr3,expr4,extern1,ptrs1,struct9,types1}.c` and
`export/{bitfields,issue216}.c`. Upstream source files are unchanged.
`upstream/execution.tsv` records these results separately for each profile.
The call profile also runs the unchanged `export/issue319.c` program, checking
its expected exit status of 48. It also executes `regression/varargs1.c` and
`varargs3.c` with a GCC F-ABI output-validation harness: the sources are unchanged,
the main symbol is renamed for the harness, and every printf format/value is
checked. This is not a full libc/stdio test. These checks do not constitute a run of all
upstream executables; 12 complete `test/c` benchmarks compile and assemble; they are not executed
by this census.
There are 203 kernel-profile and 76 call-profile rejections. Some accepted
units only define data. The existing kernel fixtures exercise native FP32.

The first milestone does not add these experimental profiles to the published
six-target artifact matrix. No release or downstream pin update is needed to
run the experiment.
