FROM docker.io/chainguard/wolfi-base:latest@sha256:43f53fe2a02ba1a9484cc560ccf188da32f4a4b38055752514d78a3923ff05c8

ARG LVM_PACKAGE_VERSION

RUN apk add --no-cache "lvm2=${LVM_PACKAGE_VERSION}"

CMD ["sleep", "infinity"]
