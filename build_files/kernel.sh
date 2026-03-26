#!/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

shopt -s nullglob

# 1. Enable Cachy Repos
coprs=(
  bieszczaders/kernel-cachyos-lto
  bieszczaders/kernel-cachyos-addons
)

for copr in "${coprs[@]}"; do
  echo "Enabling copr: $copr"
  dnf5 -y copr enable "$copr"
done

# 2. Prevent standard install triggers
pushd /usr/lib/kernel/install.d
printf '%s\n' '#!/bin/sh' 'exit 0' > 05-rpmostree.install
printf '%s\n' '#!/bin/sh' 'exit 0' > 50-dracut.install
chmod +x 05-rpmostree.install 50-dracut.install
popd

# 3. Install Cachy Kernel & Build Tools
packages=(
  kernel-cachyos-lto
  kernel-cachyos-lto-devel-matched
  clang llvm lld make git openssl
)

for pkg in kernel kernel-core kernel-modules kernel-modules-core; do
  rpm --erase $pkg --nodeps || true
done

dnf5 -y install "${packages[@]}"
dnf5 versionlock add kernel-cachyos-lto kernel-cachyos-lto-devel-matched

# 4. Extract Kernel Version
KFILE=$(ls /boot/vmlinuz-* | head -n1)
KVER="${KFILE#/boot/vmlinuz-}"

# --- START AMNEZIAWG BUILD BLOCK ---
# 5. Clone and Build with Clang (Matches Cachy LTO)
git clone https://github.com/amnezia-vpn/amneziawg-linux-kernel-module.git /tmp/awg
cd /tmp/awg/src

make -C /usr/src/kernels/"$KVER" M=$PWD \
    LLVM=1 \
    CC=clang \
    LD=ld.lld \
    modules

# 6. Install and Sign the Module
MOD_DEST="/usr/lib/modules/${KVER}/extra/amneziawg.ko"
mkdir -p "$(dirname "$MOD_DEST")"
cp amneziawg.ko "$MOD_DEST"

/usr/src/kernels/"$KVER"/scripts/sign-file sha256 \
    /secureboot/MOK.key \
    /secureboot/MOK.pem \
    "$MOD_DEST"

depmod -a "$KVER"

# 7. Cleanup build files
cd / && rm -rf /tmp/awg
# --- END AMNEZIAWG BUILD BLOCK ---

# 8. Finalize Kernel placement (Your specific bootc logic)
mv "/boot/vmlinuz-${KVER}" "/usr/lib/modules/${KVER}/vmlinuz"
mv "/boot/System.map-${KVER}" "/usr/lib/modules/${KVER}/System.map"
mv "/boot/config-${KVER}" "/usr/lib/modules/${KVER}/config"
mv "/boot/symvers-${KVER}.zst" "/usr/lib/modules/${KVER}/symvers.zst"
rm -rf /boot/*

dnf5 -y distro-sync
echo "::endgroup::"
