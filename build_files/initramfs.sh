#!/bin/bash
echo "::group:: ===$(basename "$0")==="
set -ouex pipefail
shopt -s nullglob

KVER=$(basename $(dirname $(ls /usr/lib/modules/*/vmlinuz | head -n1)))

echo "Building initramfs for kernel version: $KVER"

if [ ! -d "/usr/lib/modules/$KVER" ]; then
  echo "Error: modules missing for kernel $KVER"
  exit 1
fi

# Update dependencies (crucial to recognize the new amneziawg.ko)
depmod -a "$KVER"

export DRACUT_NO_XATTR=1
export TMPDIR="/tmp"
/usr/bin/dracut \
  --no-hostonly \
  --kver "$KVER" \
  --reproducible \
  --zstd -v \
  --add ostree --add fido2 \
  -f "/usr/lib/modules/$KVER/initramfs.img"

chmod 0600 "/usr/lib/modules/$KVER/initramfs.img"
echo "::endgroup::"
