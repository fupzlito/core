#!/bin/bash
set -ouex pipefail

system=(
  policycoreutils-python-utils
  cloud-utils-growpart
  qemu-guest-agent
  cloud-init
  distrobox
  pciutils

  avahi
  avahi-tools
  dbus
  bind-utils
  ethtool
  iptraf-ng
  iputils
  lsof
  nss-mdns
  nfs-utils
  rsync
  samba
  scp

  btop
  curl
  git
  gh
  jq
  ncdu
  tree
  tar
  unzip
  wget
)

packages=(
  ctop
  docker
  docker-compose

  tailscale
  wireguard-tools
  amneziawg-tools
)

coprs=(
  ublue-os/packages
  shiifaer/amneziawg
  fuhrmann/ctop
)


# Add tailscale repo
curl -fsSL https://pkgs.tailscale.com/stable/fedora/tailscale.repo \
  -o /etc/yum.repos.d/tailscale.repo

dnf5 -y install dnf5-plugins

# Only add amneziawg-tools if we are building for x86_64
# Note: Docker uses 'amd64', Copr/Fedora usually expects 'x86_64'
if [[ "${TARGETARCH}" == "amd64" ]]; then
    echo "Architecture is x86_64, adding AmneziaWG tools..."
    dnf5 -y copr enable shiifaer/amneziawg fedora-43-x86_64
    packages+=(amneziawg-tools)
else
    echo "Architecture is ${TARGETARCH}, skipping AmneziaWG tools (x86_64 only)."
fi

# Enable all COPRs
for copr in "${coprs[@]}"; do
  echo "Enabling copr: $copr"
  dnf5 -y copr enable "$copr"
done

# Install all packages
echo -n "max_parallel_downloads=10" >>/etc/dnf/dnf.conf
dnf5 -y install "${system[@]}"
dnf5 -y install "${packages[@]}"
dnf5 -y makecache

# Install my-caddy binary
CADDY_TAG="latest"
curl -fsSL -o /usr/bin/caddy \
  "https://github.com/fupzlito/my-caddy/releases/download/${CADDY_TAG}/caddy-linux-${TARGETARCH}"
chmod +x /usr/bin/caddy
