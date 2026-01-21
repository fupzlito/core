#!/bin/bash
echo "::group:: ===$(basename "$0")==="
set -ouex pipefail
shopt -s nullglob

RELEASE="$(rpm -E %fedora)"
DATE="$(date +%Y%m%d)"

# Host identity
echo "core" > /etc/hostname

# Create a real /etc/os-release (don’t edit /usr/lib/os-release in-place)
cat > /etc/os-release <<EOF
NAME="core"
ID="core"
VERSION="${RELEASE}.${DATE}"
VERSION_ID="${RELEASE}.${DATE}"
PRETTY_NAME="Core ${RELEASE}.${DATE}"
LOGO="cachyos"
HOME_URL="https://github.com/fupzlito/core"
DOCUMENTATION_URL="https://github.com/fupzlito/core"
SUPPORT_URL="https://github.com/fupzlito/core/issues"
BUG_REPORT_URL="https://github.com/fupzlito/core/issues"
DEFAULT_HOSTNAME="core"
CPE_NAME="cpe:/o:fupzlito:core"
EOF

# Clean repo definitions (optional: keep only Fedora official repos)
find /etc/yum.repos.d/ -maxdepth 1 -type f -name '*.repo' \
  ! -name 'fedora.repo' \
  ! -name 'fedora-updates.repo' \
  ! -name 'fedora-updates-testing.repo' \
  -exec rm -f {} +

# Cleanup caches/temp
rm -rf /tmp/* /var/tmp/* || true
dnf5 clean all || true
rm -rf /var/cache/dnf /var/cache/libdnf5 || true

echo "::endgroup::"
