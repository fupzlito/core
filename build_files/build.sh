#!/bin/bash
set -ouex pipefail

packages=(
  cloud-init
  docker
  docker-compose
  qemu-guest-agent
  tailscale
  nfs-utils
  samba
  rsync
  curl
  tree
  ncdu
)

coprs=(
  ublue-os/packages
)

dnf5 -y install dnf5-plugins

# Enable all COPRs
for copr in "${coprs[@]}"; do
  echo "Enabling copr: $copr"
  dnf5 -y copr enable "$copr"
done

# Install all packages
echo -n "max_parallel_downloads=10" >>/etc/dnf/dnf.conf
dnf5 -y install "${packages[@]}"
dnf5 -y makecache

# Install ctop binary
curl -Lo /usr/local/bin/ctop \
     -L https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64
chmod +x /usr/local/bin/ctop

# Create hawser stacks dir
install -d -m 0755 /var/srv/stacks

# Install hawser
curl -fsSL https://raw.githubusercontent.com/Finsys/hawser/main/scripts/install.sh \
| sed -E \
    -e 's#/data/stacks#/var/srv/stacks#g' \
    -e 's#ReadWritePaths=/(var/)?run/docker\.sock[[:space:]]+#ReadWritePaths=#' \
    -e '/systemctl (daemon-reload|enable|start|restart)/d' \
| bash
