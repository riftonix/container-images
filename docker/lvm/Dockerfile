FROM docker.io/chainguard/wolfi-base:latest@sha256:5172a213d2bba8b1c9ca11957db65562b52b0f9844583a0347318ea5fd8e3aa5

ARG LVM_PACKAGE_VERSION

RUN apk add --no-cache "lvm2=${LVM_PACKAGE_VERSION}"

CMD ["sleep", "infinity"]
