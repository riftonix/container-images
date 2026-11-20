FROM docker.io/chainguard/wolfi-base:latest@sha256:be019c1c74fe69204a42c4e10bc4d886a49bf5403ffa74374ef7baa408fc9a26

ARG LVM_PACKAGE_VERSION

RUN apk add --no-cache "lvm2=${LVM_PACKAGE_VERSION}"

CMD ["sleep", "infinity"]
