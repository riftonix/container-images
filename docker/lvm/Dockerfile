ARG WOLFI_BASE_DIGEST

FROM docker.io/chainguard/wolfi-base@${WOLFI_BASE_DIGEST}

ARG LVM_PACKAGE_VERSION

RUN apk add --no-cache "lvm2=${LVM_PACKAGE_VERSION}"

CMD ["sleep", "infinity"]
