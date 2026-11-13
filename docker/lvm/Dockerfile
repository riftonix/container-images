FROM docker.io/chainguard/wolfi-base:latest@sha256:ae9575b121f5776e2f04e192064bc2c5665af9d1c425d620dc773aca31698712

ARG LVM_PACKAGE_VERSION

RUN apk add --no-cache "lvm2=${LVM_PACKAGE_VERSION}"

CMD ["sleep", "infinity"]
