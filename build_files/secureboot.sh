#!/bin/bash
echo "::group:: ===$(basename "$0")==="
set -ouex pipefail
shopt -s nullglob

# 1. Dynamically find the kernel installed by kernel.sh
KVER=$(basename $(dirname $(ls /usr/lib/modules/*/vmlinuz | head -n1)))
KIMAGE="/usr/lib/modules/$KVER/vmlinuz"

# 2. Define Secure Boot paths and static GUID
SIGN_DIR="/usr/lib/bootc/install/secureboot-keys"
AUTO_KEYS_DIR="/usr/lib/bootc/install/secureboot-keys/cachyos-custom"
OWNER_GUID="8F4B4D07-F4B0-40C9-A658-496262E0BAF9" # Static UUID (run uuidgen to generate}

# 3. Install tools
dnf5 -y install sbsigntools efitools util-linux

# 4. Sign the Kernel
sbsign --key "${SIGN_DIR}/MOK.key" --cert "${SIGN_DIR}/MOK.pem" \
  --output "${KIMAGE}.signed" "$KIMAGE"
mv "${KIMAGE}.signed" "$KIMAGE"

# 5. Sign the stock systemd-boot binary
SDBOOT_BIN="/usr/lib/systemd/boot/efi/systemd-bootx64.efi"
sbsign --key "${SIGN_DIR}/MOK.key" --cert "${SIGN_DIR}/MOK.pem" \
  --output "$SDBOOT_BIN" "$SDBOOT_BIN"

# 6. Generate systemd-boot auto-enrollment files
mkdir -p "$AUTO_KEYS_DIR"
cert-to-efi-sig-list -g "$OWNER_GUID" "${SIGN_DIR}/MOK.pem" /tmp/db.esl

sign-efi-sig-list -k "${SIGN_DIR}/MOK.key" -c "${SIGN_DIR}/MOK.pem" db /tmp/db.esl "${AUTO_KEYS_DIR}/db.auth"
sign-efi-sig-list -k "${SIGN_DIR}/MOK.key" -c "${SIGN_DIR}/MOK.pem" KEK /tmp/db.esl "${AUTO_KEYS_DIR}/KEK.auth"
sign-efi-sig-list -k "${SIGN_DIR}/MOK.key" -c "${SIGN_DIR}/MOK.pem" PK /tmp/db.esl "${AUTO_KEYS_DIR}/PK.auth"

# 7. Clean up
rm -f /tmp/db.esl
rm -f "${SIGN_DIR}/MOK.key" "${SIGN_DIR}/MOK.pem"
echo "::endgroup::"
