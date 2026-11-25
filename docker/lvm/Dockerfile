FROM docker.io/chainguard/wolfi-base:latest@sha256:7974283557d272e72834dfae1a9a5b98b6bdfc90ecf88b352cf2778f15c5481d

ARG LVM_PACKAGE_VERSION

RUN apk add --no-cache "lvm2=${LVM_PACKAGE_VERSION}"

CMD ["sleep", "infinity"]
