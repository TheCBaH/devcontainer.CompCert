ARG VARIANT=13
FROM debian:${VARIANT}
# Cross toolchains for tools/compcert-cross-smoke.sh: one pure "-linux-gnu"
# cross-gcc package per target (i686/x86-64/arm/aarch64), deliberately never
# gcc-multilib - it conflicts with the arm/aarch64 cross-gcc packages
# (both provide gcc-14-<triplet> for their own target-ish name, and
# gcc-multilib's package Conflicts: the cross ones outright).
# Debian only builds these cross-gcc packages from amd64/arm64/i386 hosts
# (https://packages.debian.org/trixie/gcc-aarch64-linux-gnu, etc. - armhf is
# absent); on an armhf build host only gcc-arm-linux-gnueabihf exists (it's
# armhf's own near-native match), so tools/compcert-cross-smoke.sh must skip
# the other 3 targets there rather than assume they're installed.
RUN set -eux;\
    apt-get update;\
    case "$(dpkg --print-architecture)" in\
      armhf|armel) cross='gcc-arm-linux-gnueabihf libc6-dev-armhf-cross' ;;\
      *) cross='gcc-i686-linux-gnu libc6-dev-i386-cross gcc-x86-64-linux-gnu libc6-dev-amd64-cross gcc-arm-linux-gnueabihf libc6-dev-armhf-cross gcc-aarch64-linux-gnu libc6-dev-arm64-cross' ;;\
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
    apt-get autoremove -y; apt-get clean -y ; apt-get clean; rm -rf /var/lib/apt/lists/*;\
    echo DONE
