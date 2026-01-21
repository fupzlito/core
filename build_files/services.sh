#!/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

shopt -s nullglob

disable_services=(
  podman-tcp.service
  NetworkManager-wait-online.service
)

enable_services=(
  bootc-fetch-apply-updates.service
  systemd-resolved.service
)

mask_services=(
  systemd-journald-audit.socket
  systemd-zram-generator.service
)

systemctl disable "${disable_services[@]}" || true
systemctl enable  "${enable_services[@]}"  || true
systemctl mask    "${mask_services[@]}"    || true

echo "::endgroup::"
