#!/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

shopt -s nullglob

disable_services=(
  podman.socket
  podman-tcp.service
  NetworkManager-wait-online.service
)

enable_services=(
  bootc-fetch-apply-updates.service
  systemd-resolved.service
  qemu-guest-agent
  tailscaled
  docker
)
 # serial-getty@ttyS0.service

mask_services=(
  akmods-keygen.target
  systemd-journald-audit.socket
  systemd-zram-generator.service
  akmods-keygen@akmods-keygen.service
)

systemctl disable "${disable_services[@]}" || true
systemctl enable  "${enable_services[@]}"  || true
systemctl mask    "${mask_services[@]}"    || true

echo "::endgroup::"
