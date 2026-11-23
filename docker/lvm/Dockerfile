FROM docker.io/chainguard/wolfi-base:latest@sha256:b71197549d072ad4f359219953cb065745604010f24d884d75ab46d651da9a0b

ARG LVM_PACKAGE_VERSION

RUN apk add --no-cache "lvm2=${LVM_PACKAGE_VERSION}"

CMD ["sleep", "infinity"]
