# RISC-V F-only extraction

`riscv32_fp32` targets `rv32imf_zicsr` / ILP32F; `riscv64_fp32` targets
`rv64imf_zicsr` / LP64F. Both use native FP32 and require no D extension.
The default `compcert.ini` selects `abi=fp32`, the packaged runtime and headers.

Build and install with OCaml, dune, menhirLib, make and the matching RISC-V GCC
cross toolchain available. Rocq and a CompCert checkout are not needed:

```sh
prefix="$PWD/install"
opam exec -- ./install.sh "$prefix"
"$prefix/bin/ccomp" -nostdlib -static -no-pie \
  "$prefix/lib/compcert/crt0.o" hello.c -o hello
qemu-riscv32 -cpu rv32,d=false ./hello
```

Use qemu-riscv64 and rv64 for the 64-bit archive. The supplied startup and
stdio use Linux system calls; bare-metal users supply their own startup/I/O.
The runtime includes integer helpers, variadic functions, printf/snprintf,
several string/byte primitives and integer-based FP32/FP64 conversions. It is
not a full libc: allocation, streams, locale and libm are not supplied. All
linked code must use the same ABI and avoid D instructions.

`double` keeps 64-bit storage and the standard F ABI, including normal float
promotion through variadic calls. Double arithmetic/comparisons and dynamic
integer conversions are rejected by default. `-ffp32-approx-double` explicitly
enables FP32-backed double computation using the packaged helpers. This loses
binary64 precision/range. `-fall` does not enable it. Aggregate interfaces need
`-fstruct-passing` or `-fall`. Long-double interfaces and inline assembly remain
unsupported.

The source lowering, conversion/approximation helpers, aggregate bridges and
F-only machine connection are experimental and unverified. Existing CompCert
proofs do not establish a new end-to-end source correctness theorem for them.
Raw Asm.program consumers must also emit StructPassing.fp32_assembly().

The compiler sources are covered by LICENSE. The F-only runtime's added code
is covered by runtime/FP32-LICENSE; CompCert-derived headers/helpers retain
their source notices. Nanoprintf's license is in runtime/nanoprintf/LICENSE.
MANIFEST records source revisions, patches and file hashes.
