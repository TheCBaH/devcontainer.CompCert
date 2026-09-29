#!/usr/bin/env bash
# CompCert-side target table: the six architectures the extractor builds,
# verifies and packages. Hand-owned, and independent of the assembler:
# nothing here is generated or read from asm/.
#
# target_config <t> sets CONFIGURE_TARGET, TOOLPREFIX, QEMU_BIN, QEMU_SYSROOT,
# CCOMP_EXTRA_ARGS, COMPCERT_CONFIGURE_ARGS, AS_FLAGS and READELF_MACHINE.
#
# Even x86_32/x86_64 use a dedicated cross-gcc package rather than the host's
# gcc -m32/-m64: gcc-multilib conflicts with the arm/aarch64 cross-gcc packages.
# The RISC-V profiles are freestanding (no target libc probe), hence the extra
# configure arguments.
COMPCERT_TARGETS=(x86_32 x86_64 arm aarch64 riscv32 riscv64)
LIBC_SMOKE_TARGETS=("${COMPCERT_TARGETS[@]}")

target_config() {
  CONFIGURE_TARGET=""
  TOOLPREFIX=""
  QEMU_BIN=""
  QEMU_SYSROOT=""
  CCOMP_EXTRA_ARGS=()
  COMPCERT_CONFIGURE_ARGS=()
  READELF_MACHINE=""
  AS_FLAGS=()
  case "$1" in
    x86_32)
      CONFIGURE_TARGET="x86_32-linux"
      TOOLPREFIX="i686-linux-gnu-"
      QEMU_BIN="qemu-i386"
      QEMU_SYSROOT="/usr/i686-linux-gnu"
      CCOMP_EXTRA_ARGS=(-fno-pie)
      READELF_MACHINE="Intel 80386"
      ;;
    x86_64)
      CONFIGURE_TARGET="x86_64-linux"
      TOOLPREFIX="x86_64-linux-gnu-"
      QEMU_BIN="qemu-x86_64"
      QEMU_SYSROOT="/usr/x86_64-linux-gnu"
      CCOMP_EXTRA_ARGS=(-fno-pie)
      READELF_MACHINE="Advanced Micro Devices X86-64"
      ;;
    arm)
      CONFIGURE_TARGET="arm-linux"
      TOOLPREFIX="arm-linux-gnueabihf-"
      QEMU_BIN="qemu-arm"
      QEMU_SYSROOT="/usr/arm-linux-gnueabihf"
      CCOMP_EXTRA_ARGS=(-marm -fno-pie)
      AS_FLAGS=(-march=armv7-a)
      READELF_MACHINE="ARM"
      ;;
    aarch64)
      CONFIGURE_TARGET="aarch64-linux"
      TOOLPREFIX="aarch64-linux-gnu-"
      QEMU_BIN="qemu-aarch64"
      QEMU_SYSROOT="/usr/aarch64-linux-gnu"
      CCOMP_EXTRA_ARGS=(-fno-pie)
      READELF_MACHINE="AArch64"
      ;;
    riscv32)
      CONFIGURE_TARGET="rv32-linux"
      TOOLPREFIX="riscv32-linux-gnu-"
      QEMU_BIN="qemu-riscv32"
      QEMU_SYSROOT="/usr/riscv32-linux-gnu"
      CCOMP_EXTRA_ARGS=(-fno-pie)
      COMPCERT_CONFIGURE_ARGS=(-no-runtime-lib -no-standard-headers)
      AS_FLAGS=(-march=rv32imafd -mabi=ilp32d -mno-relax)
      READELF_MACHINE="RISC-V"
      ;;
    riscv64)
      CONFIGURE_TARGET="rv64-linux"
      TOOLPREFIX="riscv64-linux-gnu-"
      QEMU_BIN="qemu-riscv64"
      QEMU_SYSROOT="/usr/riscv64-linux-gnu"
      CCOMP_EXTRA_ARGS=(-fno-pie)
      COMPCERT_CONFIGURE_ARGS=(-no-runtime-lib -no-standard-headers)
      AS_FLAGS=(-march=rv64imafd -mabi=lp64d -mno-relax)
      READELF_MACHINE="RISC-V"
      ;;
    *)
      echo "FATAL: unknown target '$1' (targets: ${COMPCERT_TARGETS[*]})" >&2
      return 1
      ;;
  esac
}
