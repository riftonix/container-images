FROM docker.io/chainguard/wolfi-base:latest@sha256:580c9ae79c0229cc381475fbfbed0d91fab5d6606e57cd78732f9836de109e90

ARG LVM_PACKAGE_VERSION

RUN apk add --no-cache "lvm2=${LVM_PACKAGE_VERSION}"

CMD ["sleep", "infinity"]
