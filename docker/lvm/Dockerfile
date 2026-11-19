FROM docker.io/chainguard/wolfi-base:latest@sha256:71f52fd289650f1d021d60ba11235550b1b5ce124f3797bd254ca70c4cef39f9

ARG LVM_PACKAGE_VERSION

RUN apk add --no-cache "lvm2=${LVM_PACKAGE_VERSION}"

CMD ["sleep", "infinity"]
