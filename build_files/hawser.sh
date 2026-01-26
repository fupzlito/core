#!/usr/bin/env bash
set -euo pipefail

# ---- 1) Install Hawser binary ----
curl -fsSL https://github.com/Finsys/hawser/releases/latest/download/hawser_linux_amd64.tar.gz | tar xz
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
install -d -o root -g root -m 0755 /srv/hawser

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
