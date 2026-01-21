#!/bin/bash
set -ouex pipefail

coprs=(
  ublue-os/packages
)

packages=(
  cloud-init
  docker
  docker-compose
  qemu-guest-agent
  tailscale
  samba
  nfs-utils
  curl
)

dnf5 -y install dnf5-plugins

# Enable COPRs
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

# Clean up
# find /etc/yum.repos.d/ -maxdepth 1 -type f -name '*.repo' ! -name 'fedora.repo' ! -name 'fedora-updates.repo' ! -name 'fedora-updates-testing.repo' -exec rm -f {} +
# rm -rf /tmp/* || true
# dnf5 clean all

# Systemd services
systemctl mask systemd-journald-audit.socket
systemctl mask systemd-zram-generator.service

systemctl disable --now podman.socket || true

systemctl enable docker qemu-guest-agent tailscaled

#ln -s /usr/lib/systemd/system/cloud-init-local.service /etc/systemd/system/multi-user.target.wants/cloud-init-local.service
#ln -s /usr/lib/systemd/system/cloud-init.service /etc/systemd/system/multi-user.target.wants/cloud-init.service
#ln -s /usr/lib/systemd/system/cloud-config.service /etc/systemd/system/multi-user.target.wants/cloud-config.service
#ln -s /usr/lib/systemd/system/cloud-final.service /etc/systemd/system/multi-user.target.wants/cloud-final.service
