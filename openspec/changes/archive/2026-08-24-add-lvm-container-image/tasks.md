## 1. Wolfi Feasibility

- [x] 1.1 Identify current Wolfi base and `lvm2` package versions, architectures, package revision format, and Renovate-compatible datasources.
- [x] 1.2 Inspect the Wolfi `lvm2` package contents, transitive dependencies, linked libraries, default configuration, and provided `lvm`, `pvcreate`, `vgcreate`, and `vgs` commands.
- [x] 1.3 Confirm the base-provided `sleep infinity` behavior and record any additional runtime package that testing proves necessary.
- [x] 1.4 Identify the authoritative and practical registry source for the Wolfi base image, compare Chainguard Registry and Docker Hub availability, and select a digest-pinnable multi-platform reference.

## 2. LVM Image Component

- [x] 2.1 Create `docker/lvm/Dockerfile` from the pinned Wolfi base, install the pinned `lvm2` package and only validated runtime dependencies, and set `CMD ["sleep", "infinity"]`.
- [x] 2.2 Add `docker/lvm/docker-bake.json` with `WOLFI_BASE_DIGEST` and `LVM_PACKAGE_VERSION` variables, using each variable's `description` field for Renovate metadata.
- [x] 2.3 Configure the `lvm` Bake target, versioned `lvm` image tag, OCI source/base/component labels, and validated platform list.
- [x] 2.4 Ensure the tag is exactly `${REGISTRY}/${REPOSITORY_PREFIX}/lvm:${LVM_PACKAGE_VERSION}` and excludes the Wolfi base digest, sleep behavior, and separate image revision logic.

## 3. Runtime Verification

- [x] 3.1 Add fast image checks for required command presence, reported LVM2 version, readable default LVM configuration, and persistent default command behavior.
- [x] 3.2 Define a safe privileged validation using a disposable loop-backed block device, constrained LVM device discovery, and cleanup for both success and failure paths.
- [x] 3.3 Run the privileged validation in an isolated environment and determine whether `/dev/mapper/control`, `/run/udev`, `/run/lvm`, or additional packages are required for the intended Kubernetes use.
- [x] 3.4 Confirm package availability and required checks for `linux/amd64` and `linux/arm64`, removing and documenting any unsupported platform.

## 4. Pipeline Integration

- [x] 4.1 Validate changed-component discovery and release marker rendering for `docker/lvm` and its package-derived image tag.
- [x] 4.2 Run the allowed lightweight image checks and inspect the Bake publication dry run; leave any privileged or heavy container validation as an explicit user-run command when the local environment is unsuitable.

## 5. Documentation

- [x] 5.1 Add an LVM image reference page covering the image name, immutable version scheme, installed package, default command, supported platforms, and required privileged runtime access.
- [x] 5.2 Update the reference index, root documentation index when appropriate, repository layout, and dependency update reference for the new component and managed pins.
- [x] 5.3 Document the exact privileged validation command, disposable-device safety requirements, selected base, and confirmed runtime mount requirements or platform limitations.

## 6. OpenSpec Verification

- [x] 6.1 Validate the OpenSpec change in strict mode and resolve all proposal, design, spec, and task consistency errors.
