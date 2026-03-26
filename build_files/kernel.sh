#!/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

shopt -s nullglob

coprs=(
  bieszczaders/kernel-cachyos-lto
  bieszczaders/kernel-cachyos-addons
)

for copr in "${coprs[@]}"; do
  echo "Enabling copr: $copr"
  dnf5 -y copr enable "$copr"
done

pushd /usr/lib/kernel/install.d
printf '%s\n' '#!/bin/sh' 'exit 0' > 05-rpmostree.install
printf '%s\n' '#!/bin/sh' 'exit 0' > 50-dracut.install
chmod +x  05-rpmostree.install 50-dracut.install
popd

packages=(
  kernel-cachyos-lto
  kernel-cachyos-lto-devel-matched
)

for pkg in kernel kernel-core kernel-modules kernel-modules-core; do
  rpm --erase $pkg --nodeps
done

dnf5 -y install "${packages[@]}"
dnf5 versionlock add "${packages[@]}"

# Fix for Cachy Kernel not installing properly
rm -rf "/usr/lib/modules/$(ls /usr/lib/modules | head -n1)"

KFILE=$(ls /boot/vmlinuz-* | head -n1)
KVER="${KFILE#/boot/vmlinuz-}"



# 1. Install Build Tools and Headers
dnf5 install -y git make gcc kernel-cachyos-lto-devel-matched openssl

# 2. Clone and Build directly (Fastest way in CI)
git clone https://github.com/amnezia-vpn/amneziawg-linux-kernel-module.git /tmp/awg
cd /tmp/awg

# We need to point 'make' to your specific Cachy kernel headers
make -C /usr/src/kernels/"$KVER" M=$PWD modules

# 3. Install the module to the correct directory
# This creates /usr/lib/modules/$KVER/extra/amneziawg.ko
mkdir -p /usr/lib/modules/"$KVER"/extra/
cp amneziawg.ko /usr/lib/modules/"$KVER"/extra/

# 4. Sign the module for Secure Boot
MOD="/usr/lib/modules/$KVER/extra/amneziawg.ko"

echo "Signing AmneziaWG module for Secure Boot..."
/usr/src/kernels/"$KVER"/scripts/sign-file sha256 \
    /secureboot/MOK.key \
    /secureboot/MOK.pem \
    "$MOD"

# 5. Cleanup
cd / && rm -rf /tmp/awg

# 6. Final verification
modinfo "$MOD" | grep -E "signer|crypto"


mv "/boot/vmlinuz-${KVER}" "/usr/lib/modules/${KVER}/vmlinuz"
mv "/boot/System.map-${KVER}" "/usr/lib/modules/${KVER}/System.map"
mv "/boot/config-${KVER}" "/usr/lib/modules/${KVER}/config"
mv "/boot/symvers-${KVER}.zst" "/usr/lib/modules/${KVER}/symvers.zst"
rm -rf /boot/*

dnf5 -y distro-sync

echo "::endgroup::"
