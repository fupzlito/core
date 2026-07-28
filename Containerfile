FROM scratch AS ctx
COPY build_files /

# Base Image
FROM quay.io/bootc-devel/fedora-bootc-43-minimal-plus
RUN alternatives --set iptables /usr/sbin/iptables-nft

ARG TARGETOS
ARG TARGETARCH
ARG TARGETPLATFORM

COPY files/ /

# Add brew
COPY --from=ghcr.io/ublue-os/brew:latest /system_files /
RUN /usr/bin/systemctl preset brew-setup.service && \
    /usr/bin/systemctl preset brew-update.timer && \
    /usr/bin/systemctl preset brew-upgrade.timer


# Guarded copy: only attempt to copy EFI updates if they exist
RUN mkdir -p /usr/lib/bootupd/updates && \
    if find /usr/lib/efi -mindepth 3 -maxdepth 3 -type f | read; then \
      find /usr/lib/efi -mindepth 3 -maxdepth 3 -type f -exec cp -t /usr/lib/bootupd/updates {} +; \
    else \
      echo "No EFI updates found, skipping copy"; \
    fi

ARG TARGETARCH
ARG TARGETOS

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    TARGETOS=$TARGETOS TARGETARCH=$TARGETARCH TARGETPLATFORM=$TARGETPLATFORM \
    /ctx/build.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/hawser.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/var \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/services.sh


# 1. Run Kernel Script (AMD64 Only)
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/var \
    --mount=type=tmpfs,dst=/tmp \
    if [ "$TARGETARCH" = "amd64" ]; then /ctx/kernel.sh; else echo "Skipping kernel for $TARGETARCH"; fi

# 2. Run Initramfs Script (AMD64 Only)
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/var \
    --mount=type=tmpfs,dst=/tmp \
    if [ "$TARGETARCH" = "amd64" ]; then /ctx/initramfs.sh; else echo "Skipping initramfs for $TARGETARCH"; fi


RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/var \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/finalize.sh


# Inject kargs
COPY kargs/console.toml /usr/lib/bootc/kargs.d/console.toml

### LINTING
## Verify final image and contents are correct.
RUN if [ "$TARGETARCH" = "amd64" ]; then bootc container lint; else echo "Skipping bootc lint on $TARGETARCH due to QEMU emulation limits"; fi
