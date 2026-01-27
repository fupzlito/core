#!/bin/bash
set -ouex pipefail

packages=(
  cloud-utils-growpart
  qemu-guest-agent
  docker-compose
  docker
  cloud-init
  distrobox
  tailscale
  avahi-tools
  nss-mdns
  avahi
  dbus
  nfs-utils
  samba
  rsync
  curl
  tree
  ncdu
  scp
  git
  gh
)

coprs=(
  ublue-os/packages
)


# Add tailscale repo
dnf config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo

curl -fsSL https://pkgs.tailscale.com/stable/fedora/tailscale.repo \
  -o /etc/yum.repos.d/tailscale.repo

dnf5 update
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
