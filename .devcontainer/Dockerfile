ARG VARIANT=13
FROM debian:${VARIANT}
# Cross toolchains for tools/compcert-cross-smoke.sh: one pure "-linux-gnu"
# cross-gcc package per target (i686/x86-64/arm/aarch64), deliberately never
# gcc-multilib - it conflicts with the arm/aarch64 cross-gcc packages
# (both provide gcc-14-<triplet> for their own target-ish name, and
# gcc-multilib's package Conflicts: the cross ones outright). Using the
# cross packages uniformly for x86 too, instead of relying on the host's
# native gcc via -m32/-m64, also keeps the package list identical no matter
# which architecture this image itself is built for.
RUN set -eux;\
    apt-get update;\
    env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends\
  ca-certificates\
  curl\
  gcc-aarch64-linux-gnu\
  gcc-arm-linux-gnueabihf\
  gcc-i686-linux-gnu\
  gcc-x86-64-linux-gnu\
  git\
  libc6-dev-amd64-cross\
  libc6-dev-arm64-cross\
  libc6-dev-armhf-cross\
  libc6-dev-i386-cross\
  make\
  qemu-user\
  wget\
  xz-utils\
;\
    apt-get autoremove -y; apt-get clean -y ; apt-get clean; rm -rf /var/lib/apt/lists/*;\
    echo DONE
