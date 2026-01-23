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

# Install Distrobox
curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sudo sh

# Create hawser stacks dir
install -d -m 0755 /var/srv/stacks

# Install hawser
#curl -fsSL https://raw.githubusercontent.com/Finsys/hawser/main/scripts/install.sh \
#| sed -E \
#    -e 's#/data/stacks#/var/srv/stacks#g' \
#    -e 's#ReadWritePaths=/(var/)?run/docker\.sock[[:space:]]+#ReadWritePaths=#' \
#    -e '/systemctl (daemon-reload|enable|start|restart)/d' \
#| bash
curl -fsSL https://raw.githubusercontent.com/Finsys/hawser/main/scripts/install.sh -o /tmp/hawser-install.sh

# Make installer use /var/srv/stacks instead of /data/stacks (everywhere)
sed -i -E 's#/data/stacks#/var/srv/stacks#g' /tmp/hawser-install.sh
# Remove systemctl calls (build env has no systemd)
sed -i -E '/systemctl (daemon-reload|enable|start|restart)/d' /tmp/hawser-install.sh

bash /tmp/hawser-install.sh
rm -f /tmp/hawser-install.sh

for u in /etc/systemd/system/hawser.service /usr/lib/systemd/system/hawser.service; do
  [ -f "$u" ] || continue
  # Remove docker.sock from ReadWritePaths (fixes 226/NAMESPACE)
  sed -i -E 's#^ReadWritePaths=/(var/)?run/docker\.sock[[:space:]]+#ReadWritePaths=#' "$u"
  # Ensure stacks path is /var/srv/stacks (in case upstream changes it later)
  sed -i -E 's#/data/stacks#/var/srv/stacks#g' "$u"
done


cfg=/etc/hawser/config
install -d -m 0755 /etc/hawser

if [ -f "$cfg" ]; then
  if grep -q '^STACKS_DIR=' "$cfg"; then
    sed -i -E 's#^STACKS_DIR=.*#STACKS_DIR=/var/srv/stacks#' "$cfg"
  else
    printf '\nSTACKS_DIR=/var/srv/stacks\n' >>"$cfg"
  fi
else
  printf 'STACKS_DIR=/var/srv/stacks\n' >"$cfg"
fi
