FROM docker.io/chainguard/wolfi-base:latest@sha256:4cf5932a0f95a88af352f77e4efa67480cab0e1f7a48f0eddca3cce003a7c0fb

ARG LVM_PACKAGE_VERSION

RUN apk add --no-cache "lvm2=${LVM_PACKAGE_VERSION}"

CMD ["sleep", "infinity"]
