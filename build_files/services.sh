#!/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

shopt -s nullglob

disable_services=(
  podman.socket
  podman-tcp.service
  systemd-resolved.service
  NetworkManager-wait-online.service
)

enable_services=(
  bootc-fetch-apply-updates.service
  qemu-guest-agent.service
  avahi-daemon.service
  tailscaled.service
  docker.service
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
