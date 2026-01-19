#!/bin/bash

set -ouex pipefail

### Install packages
dnf5 install -y docker qemu-guest-agent tailscale samba nfs-utils



dnf5 -y copr enable rhcontainerbot/docker-compose
dnf5 -y copr enable bcicen/ctop

dnf5 install -y docker-compose-plugin
dnf5 -y install ctop

dnf5 -y copr disable rhcontainerbot/docker-compose
dnf5 -y copr disable bcicen/ctop

dnf5 clean all
rm -rf /var/cache/dnf

### Set systemd
systemctl enable docker qemu-guest-agent tailscaled
systemctl disable --now podman.socket || true
