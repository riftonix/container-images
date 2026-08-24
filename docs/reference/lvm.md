# lvm

OCI image providing LVM2 tools for privileged block-device administration.
The image installs the exact Wolfi `lvm2` package selected by the Bake manifest
and does not perform storage changes automatically.

- Location: `docker/lvm/`
- Base image: `docker.io/chainguard/wolfi-base@${WOLFI_BASE_DIGEST}`
- Publish tag: `${REGISTRY}/${REPOSITORY_PREFIX}/lvm:${LVM_PACKAGE_VERSION}`
- Default command: `sleep infinity`
- Platforms: `linux/amd64`, `linux/arm64`

For example, an `LVM_PACKAGE_VERSION` value of `2.03.42-r1` produces an image
tag ending in `:2.03.42-r1`. The package revision is intentionally part of the
image tag so the tag identifies the exact installed Wolfi package.

## Build Arguments

| Argument | Bake variable | Purpose |
| --- | --- | --- |
| `WOLFI_BASE_DIGEST` | `WOLFI_BASE_DIGEST` | Multi-platform OCI index digest for the Wolfi base image |
| `LVM_PACKAGE_VERSION` | `LVM_PACKAGE_VERSION` | Exact Wolfi `lvm2` package version used by `apk add` and the image tag |

The `lvm2` package supplies `lvm`, `pvcreate`, `vgcreate`, `vgs`, the default
configuration under `/etc/lvm/`, and its required device-mapper libraries.
Runtime dependencies are installed transitively by apk.

## Runtime Requirements

Physical-volume and volume-group operations require:

- a privileged container;
- access to host block devices through a `/dev` mount;
- `/dev/mapper/control`, which is included by the `/dev` mount.

Validation confirmed that `pvcreate`, `vgcreate`, `vgs`, `vgremove`, and
`pvremove` work on a disposable block device with these settings. Separate
mounts for `/run/udev` and `/run/lvm` were not required. No additional
`device-mapper`, `util-linux`, `udev`, or `coreutils` package is required in
the image.

The default command keeps the container available for `kubectl exec`. A
Kubernetes workload can override it with its own shell command and storage
initialization script. Device names and volume-group policy remain outside the
image.

## Privileged Validation

The following check creates a disposable loop device, limits LVM discovery to
that device, exercises the physical-volume and volume-group lifecycle, and
cleans up all temporary resources. Set `IMAGE` to the image tag being tested.

```bash
IMAGE="ghcr.io/riftonix/container-images/lvm:<version>"
BACKING_FILE="$(mktemp /tmp/lvm-container-test.XXXXXX.img)"
LOOP_DEVICE=""
VG_NAME="lvm-container-test-vg"

cleanup() {
  if [ -n "$LOOP_DEVICE" ]; then
    docker run --rm --privileged -v /dev:/dev "$IMAGE" sh -c \
      "vgremove -ff -y '$VG_NAME' >/dev/null 2>&1 || true; \
       pvremove -ff -y '$LOOP_DEVICE' >/dev/null 2>&1 || true" || true
    docker run --rm --privileged -v /dev:/dev alpine:3.22 sh -ceu \
      "apk add --no-cache losetup >/dev/null; losetup -d '$LOOP_DEVICE'" || true
  fi
  rm -f "$BACKING_FILE"
}
trap cleanup EXIT

truncate -s 64M "$BACKING_FILE"
LOOP_DEVICE="$(
  docker run --rm --privileged \
    -v /dev:/dev \
    -v "$BACKING_FILE":/tmp/lvm-test.img \
    alpine:3.22 sh -ceu \
    'apk add --no-cache losetup >/dev/null; losetup --find --show /tmp/lvm-test.img'
)"

docker run --rm --privileged -v /dev:/dev "$IMAGE" sh -ceu '
  device="$1"
  vg="$2"
  config="devices { filter=[ \"a|^${device}$|\", \"r|.*|\" ] }"

  test -b "$device"
  test -c /dev/mapper/control
  pvcreate --config "$config" -ff -y "$device"
  vgcreate --config "$config" "$vg" "$device"
  vgs --config "$config" --noheadings -o vg_name "$vg" | grep -q "$vg"
  vgremove --config "$config" -ff -y "$vg"
  pvremove --config "$config" -ff -y "$device"
' sh "$LOOP_DEVICE" "$VG_NAME"
```

Run this only on a disposable development host. Although the LVM filter limits
discovery to the temporary loop device, the containers run with full host
device access.

## Renovate Metadata

Both Bake variables carry Renovate annotations in their `description` fields.

| Variable | Datasource | Dependency | Versioning |
| --- | --- | --- | --- |
| `WOLFI_BASE_DIGEST` | `docker` | `chainguard/wolfi-base` | `docker` |
| `LVM_PACKAGE_VERSION` | `custom.wolfi` | `lvm2` | `loose` |

See [Dependency updates](dependency-updates.md) for the shared annotation
format.
