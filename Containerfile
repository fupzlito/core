FROM scratch AS ctx
COPY build_files /

# Base Image
FROM quay.io/bootc-devel/fedora-bootc-43-minimal-plus

ARG TARGETOS
ARG TARGETARCH
ARG TARGETPLATFORM

COPY files/ /

# Add brew
COPY --from=ghcr.io/ublue-os/brew:latest /system_files /
RUN /usr/bin/systemctl preset brew-setup.service && \
    /usr/bin/systemctl preset brew-update.timer && \
    /usr/bin/systemctl preset brew-upgrade.timer


RUN mkdir -p /usr/lib/bootupd/updates \
    && cp -r /usr/lib/efi/*/*/* /usr/lib/bootupd/updates

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

# 1. Run CachyOS Kernel logic ONLY on arm64
# Stage 2a: AMD64 Branch (Installs CachyOS Kernel)
FROM base-common AS branch-amd64
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/var \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/kernel.sh
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/var \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/initramfs.sh


# Stage 2b: ARM64 Branch (Does nothing, stays stock)
FROM base-common AS branch-arm64
RUN echo "ARM64 detected: Skipping CachyOS kernel/initramfs scripts."

# --- THE MERGE ---

# Stage 3: Final Image (Steps for BOTH AMD and ARM)
FROM branch-${TARGETARCH} AS final


RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/var \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/finalize.sh

# Inject kargs
COPY kargs/console.toml /usr/lib/bootc/kargs.d/console.toml

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
