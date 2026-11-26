FROM docker.io/chainguard/wolfi-base:latest@sha256:c902a861151182e4ce2de29b8632ba3f7d75b68c35880580f16e353819e524d3

ARG LVM_PACKAGE_VERSION

RUN apk add --no-cache "lvm2=${LVM_PACKAGE_VERSION}"

CMD ["sleep", "infinity"]
