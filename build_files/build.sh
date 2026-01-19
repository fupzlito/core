#!/bin/bash

set -ouex pipefail

### Install packages
dnf5 install -y qemu-guest-agent tailscale samba nfs-utils
dnf5 install -y docker docker-compose

dnf5 install -y 'dnf5-command(copr)'
dnf5 -y copr enable bcicen/ctop

dnf5 install -y ctop

dnf5 -y copr disable bcicen/ctop

dnf5 clean all
rm -rf /var/cache/dnf

### Set systemd
systemctl enable docker qemu-guest-agent tailscaled
systemctl disable --now podman.socket || true
