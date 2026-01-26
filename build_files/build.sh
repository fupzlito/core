#!/bin/bash
set -ouex pipefail

packages=(
  qemu-guest-agent
  docker-compose
  docker
  cloud-init
  distrobox
  tailscale
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


# Install hawser
curl -fsSL https://raw.githubusercontent.com/Finsys/hawser/main/scripts/install.sh -o /tmp/hawser-install.sh

# Make installer use /var/lib/hawser/stacks instead of /data/stacks (everywhere)
sed -i -E 's#/data/stacks#/var/lib/hawser/stacks#g' /tmp/hawser-install.sh

# Remove systemctl calls (build env has no systemd)
sed -i -E '/systemctl (daemon-reload|enable|start|restart)/d' /tmp/hawser-install.sh

bash /tmp/hawser-install.sh
rm -f /tmp/hawser-install.sh

# Make Hawser data dir
install -d -o root -g root -m 0755 /var/lib/hawser/stacks

for u in /etc/systemd/system/hawser.service /usr/lib/systemd/system/hawser.service; do
  [ -f "$u" ] || continue

  # Remove docker.sock from ReadWritePaths (fixes 226/NAMESPACE)
  sed -i -E 's#^ReadWritePaths=/(var/)?run/docker\.sock[[:space:]]+#ReadWritePaths=#' "$u"

  # Ensure stacks path is /var/lib/hawser/stacks
  sed -i -E 's#/data/stacks#/var/lib/hawser/stacks#g' "$u"

  # Ensure ReadWritePaths includes stacks dir (needed with ProtectSystem=strict)
  if grep -q '^ReadWritePaths=' "$u"; then
    grep -q '/var/lib/hawser/stacks' "$u" || \
      sed -i -E 's#^ReadWritePaths=(.*)#ReadWritePaths=\1 /var/lib/hawser/stacks#' "$u"
  else
    printf '\nReadWritePaths=/var/lib/hawser/stacks\n' >>"$u"
  fi
done

cfg=/etc/hawser/config
install -d -m 0755 /etc/hawser

if [ -f "$cfg" ]; then
  if grep -q '^STACKS_DIR=' "$cfg"; then
    sed -i -E 's#^STACKS_DIR=.*#STACKS_DIR=/var/lib/hawser/stacks#' "$cfg"
  else
    printf '\nSTACKS_DIR=/var/lib/hawser/stacks\n' >>"$cfg"
  fi
else
  printf 'STACKS_DIR=/var/lib/hawser/stacks\n' >"$cfg"
fi
