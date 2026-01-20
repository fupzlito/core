#!/bin/bash
set -ouex pipefail

# Install all required packages
dnf5 install -y cloud-init docker docker-compose qemu-guest-agent tailscale samba nfs-utils curl systemd-boot-unsigned systemd-ukify


# Install ctop static binary
curl -Lo /usr/local/bin/ctop \
     -L https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64
chmod +x /usr/local/bin/ctop

# Clean up
dnf5 clean all
rm -rf /var/cache/dnf

# Systemd services
systemctl mask systemd-journald-audit.socket
systemctl mask systemd-zram-generator.service

systemctl disable --now podman.socket || true

systemctl enable docker qemu-guest-agent tailscaled

#ln -s /usr/lib/systemd/system/cloud-init-local.service /etc/systemd/system/multi-user.target.wants/cloud-init-local.service
#ln -s /usr/lib/systemd/system/cloud-init.service /etc/systemd/system/multi-user.target.wants/cloud-init.service
#ln -s /usr/lib/systemd/system/cloud-config.service /etc/systemd/system/multi-user.target.wants/cloud-config.service
#ln -s /usr/lib/systemd/system/cloud-final.service /etc/systemd/system/multi-user.target.wants/cloud-final.service

# Build the UKI while the container is still mutable
PARTUUID=57fbe3f6-2f21-47e3-a24a-e41e5011f4af
ukify build \
  --linux /boot/vmlinuz \
  --initrd /boot/initramfs.img \
  --cmdline "root=PARTUUID=${ROOT_PARTUUID} rw" \
  --output /boot/efi/EFI/Linux/fedora-bootc.efi

# Ensure loader entries directory exists
mkdir -p /boot/efi/loader/entries

# Create the systemd-boot entry
cat > /boot/efi/loader/entries/fedora-bootc.conf <<EOF
title Fedora bootc
efi /EFI/Linux/fedora-bootc.efi
EOF
