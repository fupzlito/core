#!/bin/bash
set -ouex pipefail

# Install all required packages
dnf5 install -y docker docker-compose qemu-guest-agent tailscale samba nfs-utils curl

# Install ctop static binary
curl -Lo /usr/local/bin/ctop https://github.com/bcicen/ctop/releases/download/v0.9.8/ctop-0.9.8-linux-amd64
chmod +x /usr/local/bin/ctop

# Clean up
dnf5 clean all
rm -rf /var/cache/dnf

# Systemd services
systemctl mask systemd-journald-audit.socket
systemctl disable --now podman.socket || true
systemctl enable docker qemu-guest-agent tailscaled
