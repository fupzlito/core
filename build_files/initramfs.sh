#!/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail
shopt -s nullglob

KVER=$(ls /usr/lib/modules | head -n1)
ls "/usr/lib/modules"
ls "/usr/lib/modules/$KVER"

KIMAGE="/usr/lib/modules/$KVER/vmlinuz"
SIGN_DIR="/secureboot"

# Tools for signing + recompression
dnf5 -y install sbsigntools xz

# --- Sign kernel (UEFI Secure Boot) ---
sbsign \
  --key "$SIGN_DIR/MOK.key" \
  --cert "$SIGN_DIR/MOK.pem" \
  --output "${KIMAGE}.signed" \
  "$KIMAGE"
mv "${KIMAGE}.signed" "$KIMAGE"

# --- Sign kernel modules (optional but recommended for Secure Boot) ---
SIGNFILE="/usr/src/kernels/$KVER/scripts/sign-file"

# If sign-file isn't present, DO NOT touch modules (avoids breaking compression/layout)
if [ ! -x "$SIGNFILE" ]; then
  echo "Warning: $SIGNFILE not found/executable; skipping module signing and leaving modules untouched."
else
  # Ensure matching kernel-devel is present (provides sign-file + related bits)
  # If it's already installed, dnf5 will no-op.
  dnf5 -y install "kernel-devel-$KVER" || true

  # Fedora modules are .ko.xz with CRC32; kernel XZ decoder is picky.
  XZ_RECOMPRESS_OPTS=(--check=crc32 --lzma2=dict=1MiB -T0)

  find "/lib/modules/$KVER" -type f -name '*.ko.xz' -print0 | while IFS= read -r -d '' comp; do
    uncompressed="${comp%.xz}"

    if xz -d --keep "$comp"; then
      echo "Decompressed $comp → $uncompressed"
    else
      echo "Warning: failed to decompress $comp, skipping"
      continue
    fi

    "$SIGNFILE" sha512 "$SIGN_DIR/MOK.key" "$SIGN_DIR/MOK.pem" "$uncompressed"

    # Only replace the original compressed module AFTER signing succeeds
    rm -f "$comp"

    if xz "${XZ_RECOMPRESS_OPTS[@]}" -z "$uncompressed"; then
      echo "Recompressed and signed $uncompressed - ${uncompressed}.xz"
    else
      echo "Warning: failed to recompress $uncompressed"
      # Try not to leave the module missing if recompress fails
      # (restore original .ko.xz if it still exists is impossible now, so fail hard)
      exit 1
    fi
  done
fi

# Remove keys from final image
rm -rf "$SIGN_DIR"

echo "Building initramfs for kernel version: $KVER"

if [ ! -d "/usr/lib/modules/$KVER" ]; then
  echo "Error: modules missing for kernel $KVER"
  exit 1
fi

depmod -a "$KVER"
export TMPDIR=/tmp
export DRACUT_NO_XATTR=1

/usr/bin/dracut \
  --no-hostonly \
  --kver "$KVER" \
  --reproducible \
  --xz \
  --add ostree --add fido2 \
  -f "/usr/lib/modules/$KVER/initramfs.img"

chmod 0600 "/usr/lib/modules/$KVER/initramfs.img"

echo "::endgroup::"
