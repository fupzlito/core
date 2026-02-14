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

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/var \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/kernel.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/var \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/initramfs.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/var \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/finalize.sh


# Inject kargs
COPY kargs/console.toml /usr/lib/bootc/kargs.d/console.toml

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
