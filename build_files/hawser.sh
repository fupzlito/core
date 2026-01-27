#!/usr/bin/env bash
set -euo pipefail

# ---- 1) Install Hawser binary ----
OS=linux
ARCH=amd64
VER="${HAWSER_VERSION:-latest}"

if [ "$VER" = "latest" ]; then
  VER="$(curl -fsSL "https://api.github.com/repos/Finsys/hawser/releases/latest" \
    | sed -nE 's/.*"tag_name":[[:space:]]*"v?([^"]+)".*/\1/p' | head -n1)"
  [ -n "$VER" ] || { echo "Failed to resolve latest Hawser version"; exit 1; }
else
  VER="${VER#v}"
fi

curl -fsSL "https://github.com/Finsys/hawser/releases/download/v${VER}/hawser_${VER}_${OS}_${ARCH}.tar.gz" \
  | tar xz

install -m 0755 hawser /usr/local/bin/hawser
rm -f hawser

# ---- 2) Create config directory + config ----
install -d -m 0755 /etc/hawser

cat > /etc/hawser/config <<'EOF'
# Hawser Configuration
PORT=2376
DOCKER_SOCKET=/var/run/docker.sock
STACKS_DIR=/srv/hawser
EOF

# ---- 3) Create stacks directory (persistent via /srv -> /var/srv) ----
install -d -o root -g root -m 0755 /var/srv/hawser

# ---- 4) Install systemd unit (disabled by default) ----
cat > /etc/systemd/system/hawser.service <<'EOF'
[Unit]
Description=Hawser - Remote Docker Agent for Dockhand
Documentation=https://github.com/Finsys/hawser
After=network-online.target docker.service
Wants=network-online.target
Requires=docker.service

[Service]
Type=simple
ExecStart=/usr/local/bin/hawser
Restart=always
RestartSec=10
EnvironmentFile=/etc/hawser/config

# Security hardening
NoNewPrivileges=false
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/srv/hawser

[Install]
WantedBy=multi-user.target
EOF

# ---- 5) Done (intentionally NOT enabling or starting the service) ----
