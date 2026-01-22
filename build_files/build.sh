#!/bin/bash
set -ouex pipefail

packages=(
  cloud-init
  docker
  docker-compose
  qemu-guest-agent
  tailscale
  samba
  nfs-utils
  curl
  tree
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

# Create hawser default data dir (hawser install script expects /data/stacks)
install -d -m 0755 /data/stacks

cat >/usr/local/bin/systemctl <<'EOF'
#!/bin/sh
exit 0
EOF
chmod 0755 /usr/local/bin/systemctl

curl -fsSL https://raw.githubusercontent.com/Finsys/hawser/main/scripts/install.sh | bash

rm -f /usr/local/bin/systemctl
