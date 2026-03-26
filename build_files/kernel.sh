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



# 1. Install DKMS and Build Tools
dnf5 install -y dkms kernel-cachyos-lto-devel-matched openssl

# 2. Download AmneziaWG Source directly (since Copr is down)
git clone https://github.com/amnezia-vpn/amneziawg-linux-kernel-module.git /tmp/awg
cd /tmp/awg

# 3. Add to DKMS and Build
# The 'dkms.conf' is already in the repo
dkms add .
dkms build -m amneziawg -v $(cat version) -k "$KVER"
dkms install -m amneziawg -v $(cat version) -k "$KVER"

# 4. Manual Sign (Since we are in a container build)
MOD=$(find /usr/lib/modules/"$KVER" -name 'amneziawg.ko*')
/usr/src/kernels/"$KVER"/scripts/sign-file sha256 \
    /ctx/secureboot/MOK.key \
    /ctx/secureboot/MOK.pem \
    "$MOD"

# 5. Cleanup build files to keep the image small
rm -rf /tmp/awg


mv "/boot/vmlinuz-${KVER}" "/usr/lib/modules/${KVER}/vmlinuz"
mv "/boot/System.map-${KVER}" "/usr/lib/modules/${KVER}/System.map"
mv "/boot/config-${KVER}" "/usr/lib/modules/${KVER}/config"
mv "/boot/symvers-${KVER}.zst" "/usr/lib/modules/${KVER}/symvers.zst"
rm -rf /boot/*

dnf5 -y distro-sync

echo "::endgroup::"
