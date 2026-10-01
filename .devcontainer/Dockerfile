ARG VARIANT=13
FROM debian:${VARIANT}
ARG VARIANT
ARG RISCV32_TOOLCHAIN_TAG=v0.0.1
ENV PATH="/usr/local/riscv32-linux-gnu-toolchain/bin:${PATH}"
# Debian ships an rv64 Linux cross toolchain, but no rv32 glibc one. The
# published RV32 archive installs the sysroot at /usr/riscv32-linux-gnu and
# its tool prefix under /usr/local. There is no published 32-bit-host archive,
# so the portable 32-bit image legs leave it absent and skip cross-toolchain jobs.
# gcc-riscv64-linux-gnu only Recommends (not Depends) libc6-dev-riscv64-cross,
# and this install uses --no-install-recommends, so the rv64 glibc sysroot is
# listed explicitly rather than arriving as a side effect.
RUN set -eux;\
    apt-get update;\
    ARCH="$(dpkg --print-architecture)";\
    case "$ARCH" in\
      armhf|armel) cross='gcc-arm-linux-gnueabihf libc6-dev-armhf-cross' ;;\
      *) cross='gcc-i686-linux-gnu libc6-dev-i386-cross gcc-x86-64-linux-gnu libc6-dev-amd64-cross gcc-arm-linux-gnueabihf libc6-dev-armhf-cross gcc-aarch64-linux-gnu libc6-dev-arm64-cross binutils-riscv64-linux-gnu gcc-riscv64-linux-gnu libc6-dev-riscv64-cross' ;;\
    esac;\
    env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends\
  ca-certificates\
  curl\
  git\
  make\
  qemu-user\
  wget\
  xz-utils\
  $cross\
;\
    case "${VARIANT}:${ARCH}" in\
      12:amd64) riscv32_version='12.4.0'; riscv32_sha256='bcf2f732735e266bdc5e0053ba457e40572582a8a655cd543fa3fee6c98f8e81' ;;\
      12:arm64) riscv32_version='12.4.0'; riscv32_sha256='a44d36346c34d95927cd2c61caf75db4b1217bf0b285098ac30d701e69dc8c7f' ;;\
      13:amd64) riscv32_version='14.2.0'; riscv32_sha256='d3614cb182c72a34dcde5d78e000a561b433fb3f5fb3ffcc9d3221c1296fcc64' ;;\
      13:arm64) riscv32_version='14.2.0'; riscv32_sha256='21d0baece4b124259a99045b6b9ab6498c234c546f5b5d868e8c3df2a5adff47' ;;\
      *) riscv32_version=''; riscv32_sha256='' ;;\
    esac;\
    if [ -n "$riscv32_version" ]; then\
      riscv32_asset="riscv32-linux-gnu-${riscv32_version}-debian-${VARIANT}-${ARCH}.tar.xz";\
      curl -fsSLO "https://github.com/TheCBaH/riscv32-linux-gnu.builder/releases/download/${RISCV32_TOOLCHAIN_TAG}/${riscv32_asset}";\
      echo "${riscv32_sha256}  ${riscv32_asset}" | sha256sum -c -;\
      tar -C / -xJf "$riscv32_asset";\
      rm "$riscv32_asset";\
      riscv32-linux-gnu-gcc --version;\
    fi;\
    apt-get autoremove -y; apt-get clean -y ; apt-get clean; rm -rf /var/lib/apt/lists/*;\
    echo DONE
