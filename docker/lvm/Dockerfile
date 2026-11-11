FROM docker.io/chainguard/wolfi-base:latest@sha256:94fa13e26d449f7d78dbcd02d12ea37a0da80d24fcc3e1f17b95d515dec607a7

ARG LVM_PACKAGE_VERSION

RUN apk add --no-cache "lvm2=${LVM_PACKAGE_VERSION}"

CMD ["sleep", "infinity"]
