FROM scratch AS ctx
COPY build_files /

# Base Image
FROM quay.io/bootc-devel/fedora-bootc-43-minimal-plus

COPY files/boot /boot

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh


### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
