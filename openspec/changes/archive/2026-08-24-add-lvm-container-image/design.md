## Context

The repository builds independent OCI images from per-component Dockerfiles and `docker-bake.json` manifests. Existing CI can build any Bake component but performs no image-specific runtime assertions. The target Kubernetes DaemonSet currently uses `ubuntu:22.04`, installs `lvm2` during startup, mounts host `/dev`, runs privileged, and executes `vgs`, `pvcreate`, and `vgcreate` before sleeping indefinitely.

LVM2 is coupled to the kernel device-mapper interface and can also interact with udev state. A successful package installation or `lvm version` result therefore does not prove that physical volume and volume group operations work in a privileged container. The image must be functionally validated without risking existing host storage.

## Goals / Non-Goals

**Goals:**

- Produce a small prebuilt LVM utility image with deterministic package contents.
- Keep the image usable both with a Kubernetes command override and with its default persistent command.
- Derive release identity from the exact installed Wolfi LVM2 package version.
- Validate LVM commands against a disposable block device and document required runtime privileges and mounts.
- Integrate image versions and publication metadata with the existing Bake and Renovate conventions.

**Non-Goals:**

- Embed cluster-specific device names, volume group names, or initialization policy in the image.
- Run systemd, udevd, `lvmetad`, or `dmeventd` as container services unless functional testing proves one is required.
- Modify the Kubernetes infrastructure repository as part of this change.
- Add a floating `latest` tag.
- Build custom LVM2 packages with melange or another package builder.

## Decisions

### Name the image `lvm`

Use `docker/lvm` and publish `.../lvm:<tag>`. `lvm` describes the image's user-facing purpose, while `lvm2` remains the package name and version source. This avoids exposing a distribution package name as the product identity and produces concise Kubernetes references.

Alternatives considered:

- `lvm2`: unambiguous package identity, but couples the image name to the current package generation.
- `lvm-tools`: descriptive, but unnecessarily verbose and inconsistent with the short tool-oriented name.

### Prefer Wolfi and validate behavior before selecting it

Start with `docker.io/chainguard/wolfi-base:latest` pinned by its multi-platform OCI index digest and install the pinned `lvm2` package with apk. Docker Hub is an official Chainguard mirror of the canonical `cgr.dev/chainguard/wolfi-base` image and currently exposes identical amd64 and arm64 manifests. Use the `cgr.dev` reference as a fallback if Docker Hub rate limiting affects CI. Include only dependencies pulled by the package manager plus any dependency proven necessary by runtime tests. Inspect the installed package and linked libraries rather than preemptively adding broad packages such as `util-linux` or `coreutils`.

Wolfi is accepted only after command, configuration, default-command, and disposable block-device checks pass. On a reproducible incompatibility, repeat the same checks with Alpine. A minimal Ubuntu base is the final fallback because it is larger and uses a different packaging stack, but it offers the closest behavior to the current workload.

Alternatives considered:

- Start with Alpine: likely compatible and compact, but misses the preferred minimal, security-focused Wolfi baseline.
- Keep Ubuntu: lowest migration uncertainty, but preserves substantially more image content than required.
- Use an apko image: potentially smaller and declarative, but introduces a new image construction path that the repository does not currently use.

### Derive image identity from the Wolfi package version

Use the exact Wolfi LVM2 package version as the complete image tag, for example `2.03.42-r1`. The same `LVM_PACKAGE_VERSION` value pins `apk add`, renders the OCI version labels, and renders the public image tag. There is no separate upstream version or image revision variable.

This keeps the image tag unambiguously aligned with installed package content and gives Renovate one LVM version input to maintain.

Alternatives considered:

- Strip the distribution package revision from the tag: shorter, but requires unsupported Bake transforms or a second version variable.
- Add an independent image revision: flexible, but introduces release state that this image does not need.

### Keep cluster setup logic outside the image

The Dockerfile installs tools and defines `CMD ["sleep", "infinity"]`. It does not include an entrypoint that creates physical volumes or volume groups. Kubernetes continues to provide cluster-specific setup commands, and overriding the image command bypasses the default sleep as normal container behavior.

This prevents an image from modifying storage merely by being started and allows reuse with different device and volume group policies.

### Validate with a disposable block device

Build verification checks command presence, reported version, configuration readability, and default command behavior. Functional validation runs only in an isolated privileged environment with a disposable loop-backed file or equivalent temporary block device. It creates a physical volume and volume group, verifies them, removes them, detaches the device, and deletes the backing file.

The implementation must identify whether `/dev/mapper/control`, `/run/udev`, or `/run/lvm` access is required. It must not infer compatibility solely from static package inspection. Because the repository's current Dagger verification may not expose safe host-level block devices, the lightweight checks can run in normal CI while the privileged validation is provided as a documented, explicit verification command or a CI job with an isolated runner capability.

### Use repository-standard Bake metadata

The Bake manifest defines registry and repository defaults plus `WOLFI_BASE_DIGEST` and `LVM_PACKAGE_VERSION` variables. Each managed input uses the standard `description` field with Renovate metadata. The image tag is `${REGISTRY}/${REPOSITORY_PREFIX}/lvm:${LVM_PACKAGE_VERSION}`; the Wolfi base digest and default sleep behavior do not contribute to it. The target includes source, title, image version, base image, and exact package version labels.

The selected platforms remain `linux/amd64` and `linux/arm64` only when both can resolve packages and pass required validation. An unsupported platform is removed rather than publishing an untested manifest entry.

## Risks / Trade-offs

- Wolfi package metadata may not expose an upstream-only LVM2 version cleanly to Renovate -> select a datasource and extraction expression during implementation, and keep the exact package pin explicit in Bake metadata.
- `sleep infinity` behavior can vary between implementations -> test the selected base's `sleep` directly and add no coreutils dependency unless the default implementation fails.
- Privileged LVM tests can damage host storage if device discovery escapes the test device -> use an isolated disposable device, constrain the LVM devices configuration where possible, and clean up in failure paths.
- Multi-platform builds do not prove architecture-specific runtime compatibility -> publish only platforms covered by package availability and functional validation evidence.
- Udev behavior inside a container can differ from the Kubernetes host -> document required mounts and validate against a representative privileged environment before changing the infrastructure manifest.

## Migration Plan

1. Build and validate the Wolfi candidate without publishing it.
2. Select a fallback base only if the candidate fails a documented reproducible functional check.
3. Publish the immutable versioned image and its Git release marker through the existing workflow.
4. In a separate infrastructure change, replace the Ubuntu image and runtime package installation with the pinned `lvm` image tag.
5. Roll back the infrastructure workload to the previous Ubuntu manifest if node-level validation fails. Published image tags remain immutable and require no registry rollback.
