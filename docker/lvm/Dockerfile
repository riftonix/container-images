FROM docker.io/chainguard/wolfi-base:latest@sha256:b7787f1d3f29dcfb48730372d3515391ac3b218723201a765c94949922676099

ARG LVM_PACKAGE_VERSION

RUN apk add --no-cache "lvm2=${LVM_PACKAGE_VERSION}"

CMD ["sleep", "infinity"]
