FROM docker.io/chainguard/wolfi-base:latest@sha256:6ab86c5e059da41ff1454b6f69ecd7422b94af41969f4e231aa23244e47d4a81

ARG LVM_PACKAGE_VERSION

RUN apk add --no-cache "lvm2=${LVM_PACKAGE_VERSION}"

CMD ["sleep", "infinity"]
