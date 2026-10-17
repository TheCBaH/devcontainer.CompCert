#!/usr/bin/env bash
# CompCert-side target table: the architectures and ABI profiles the extractor builds,
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
LIBC_SMOKE_TARGETS=(x86_32 x86_64 arm aarch64 riscv32 riscv64)
COMPCERT_TARGETS=("${LIBC_SMOKE_TARGETS[@]}" riscv32_fp32 riscv64_fp32)

target_config() {
  CONFIGURE_TARGET=""
  TOOLPREFIX=""
  QEMU_BIN=""
  QEMU_SYSROOT=""
  CCOMP_EXTRA_ARGS=()
  COMPCERT_CONFIGURE_ARGS=()
  READELF_MACHINE=""
  AS_FLAGS=()
  FP32_BITS=""
  TARGET_PROFILE=standard
  QEMU_ARGS=()
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
    riscv32_fp32|riscv64_fp32)
      FP32_BITS=${1#riscv}
      FP32_BITS=${FP32_BITS%_fp32}
      TARGET_PROFILE=fp32
      CONFIGURE_TARGET="rv$FP32_BITS-fp32"
      TOOLPREFIX="riscv$FP32_BITS-linux-gnu-"
      QEMU_BIN="qemu-riscv$FP32_BITS"
      QEMU_ARGS=(-cpu "rv$FP32_BITS,d=false")
      CCOMP_EXTRA_ARGS=(-fno-pie)
      if [ "$FP32_BITS" = 32 ]; then fp32_abi=ilp32f; else fp32_abi=lp64f; fi
      AS_FLAGS=(-march="rv${FP32_BITS}imf_zicsr" -mabi="$fp32_abi" -mno-relax)
      READELF_MACHINE="RISC-V"
      ;;
    *)
      echo "FATAL: unknown target '$1' (targets: ${COMPCERT_TARGETS[*]})" >&2
      return 1
      ;;
  esac
}
