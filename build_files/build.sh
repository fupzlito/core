#!/bin/bash
set -ouex pipefail

packages=(
  curl
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
