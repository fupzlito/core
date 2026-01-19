#!/bin/bash

set -ouex pipefail

### Install packages
dnf5 install -y docker docker-compose-plugin qemu-guest-agent tailscale ctop samba nfs-utils

### Set systemd
systemctl enable docker qemu-guest-agent tailscaled
systemctl disable --now podman.socket || true

dnf5 clean all
rm -rf /var/cache/dnf
