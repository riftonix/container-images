## Why

The Kubernetes LVM setup workload currently starts from a general-purpose Ubuntu image and installs `lvm2` at runtime, which makes startup depend on package repositories and leaves the effective tool version unpinned. A dedicated, minimal LVM image will provide a reproducible toolchain that is ready before the workload starts.

## What Changes

- Add a dedicated OCI image component named `lvm` under `docker/lvm`.
- Install the `lvm2` package and required runtime dependencies in the image, preferring Wolfi as the base distribution.
- Publish the image as `ghcr.io/riftonix/container-images/lvm:<wolfi-lvm2-package-version>`, including the apk revision such as `2.03.42-r1`.
- Configure the image to run `sleep infinity` by default so it remains available as a privileged Kubernetes utility container when no command is supplied.
- Verify that the image includes the LVM commands and configuration needed for physical volume and volume group operations against host block devices.
- Fall back to Alpine only when Wolfi fails the functional device-mapper validation, and use a minimal Ubuntu base only when both apk-based options are unsuitable.
- Add Renovate-managed Bake variables for the Wolfi base digest and exact Wolfi `lvm2` package version, using the package version for installation, OCI version metadata, and the public image tag.

## Capabilities

### New Capabilities

- `lvm-container-image`: Defines the image identity, package-derived versioning, runtime behavior, required LVM functionality, and base-image selection criteria.

### Modified Capabilities

- `container-image-bake-pipeline`: Require the new LVM image component to be described, versioned, verified, and published through the repository's existing Bake pipeline.

## Impact

- Adds `docker/lvm/Dockerfile` and `docker/lvm/docker-bake.json`.
- Adds a new GHCR package path under `ghcr.io/riftonix/container-images/lvm` and matching Git release marker tags under `docker/lvm/`.
- Adds operational pins for the base image and LVM2 package version to Renovate management.
- Adds image reference documentation and updates repository layout documentation.
- Enables a later change in the Kubernetes infrastructure repository to replace runtime `apt-get install lvm2` with a pinned prebuilt image. That manifest update is outside this repository and this change.
