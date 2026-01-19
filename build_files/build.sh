#!/bin/bash
set -ouex pipefail

# Install all required packages
dnf5 install -y cloud-init docker docker-compose qemu-guest-agent tailscale samba nfs-utils curl

# Install ctop static binary
curl -Lo /usr/local/bin/ctop \
     -L https://github.com/bcicen/ctop/releases/download/v0.9.8/ctop-0.9.8-linux-amd64
chmod +x /usr/local/bin/ctop

# Clean up
dnf5 clean all
rm -rf /var/cache/dnf

# Systemd services
systemctl mask systemd-journald-audit.socket
systemctl mask systemd-zram-generator.service

systemctl disable --now podman.socket || true

systemctl enable docker qemu-guest-agent tailscaled

ln -s /usr/lib/systemd/system/cloud-init-local.service /etc/systemd/system/multi-user.target.wants/cloud-init-local.service
ln -s /usr/lib/systemd/system/cloud-init.service /etc/systemd/system/multi-user.target.wants/cloud-init.service
ln -s /usr/lib/systemd/system/cloud-config.service /etc/systemd/system/multi-user.target.wants/cloud-config.service
ln -s /usr/lib/systemd/system/cloud-final.service /etc/systemd/system/multi-user.target.wants/cloud-final.service
