# Fix LVM Dependency Pin Updates

## Why

### Initial Requirements and Drivers

The `lvm` image has not received a dependency update since it was added on 2026-08-24. Its Bake manifest pins Wolfi `lvm2` `2.03.42-r1`, while the Wolfi package definition in `wolfi-dev/os` already defines `lvm2` version `2.03.44` with epoch `1`. The Renovate Dependency Dashboard lists dependencies for the other images but none from `docker/lvm/`.

### Current Solution

`docker/lvm/docker-bake.json` defines two annotated variables:

- `WOLFI_BASE_DIGEST`, whose value is the `sha256:` digest of `chainguard/wolfi-base` and whose annotation uses the `docker` datasource.
- `LVM_PACKAGE_VERSION`, whose annotation uses the `custom.wolfi` datasource.

`docker/lvm/Dockerfile` receives the digest as a build argument and starts from `docker.io/chainguard/wolfi-base@${WOLFI_BASE_DIGEST}`. The OCI base name label is rendered from the same variable. Bake annotations are read by one shared Renovate regex manager.

### Business Problems

- The shared annotation pattern accepts only lowercase letters and hyphens in the datasource name, so the `custom.wolfi` annotation is never matched and the `lvm2` version is not tracked.
- The `custom.wolfi` datasource is not defined in the Renovate configuration, so a matched annotation would still fail to resolve versions.
- The base digest is stored where Renovate expects a version, not as a digest of a tag, so the Wolfi base is not updated either.
- As a result, the LVM image does not receive package or base updates, which the dependency pin requirement for this image expects.

## What Changes

### Goals

- Renovate detects and proposes updates for the exact Wolfi `lvm2` package version of the `lvm` image.
- Renovate detects and proposes updates for the Wolfi base image digest of the `lvm` image.

### Scope

- Allow dots in datasource names of Bake variable annotations, so repository-defined `custom.<name>` datasources are matched.
- Define the `custom.wolfi` datasource in the Renovate configuration.
- Pin the Wolfi base image in `docker/lvm/Dockerfile` as a literal tag and digest reference managed by the built-in Dockerfile manager.
- **BREAKING** for Bake overrides: remove the `WOLFI_BASE_DIGEST` variable and build argument from the `lvm` image. Overriding the base digest through Bake is no longer possible.
- Render the OCI base name label of the `lvm` image without the removed variable.
- Update the `lvm` image reference and dependency update documentation.

### Non-Goals

- Changing the `lvm` image tag scheme or the installed `lvm2` version as part of this change. The package update is expected as a separate Renovate proposal.
- Changing how images are verified or published.
- Changing dependency management of other images.

## Capabilities

### New Capabilities

None

### Modified Capabilities

- `container-image-bake-pipeline`: The LVM image dependency pin requirement moves the base image digest from a Bake variable to the Dockerfile base image reference.

## Impact

### Users and Business Processes

- Consumers of the published `lvm` image receive newer `lvm2` packages through regular Renovate updates instead of manual pin changes.
- Anyone who overrides `WOLFI_BASE_DIGEST` when building the image must change the Dockerfile reference instead.

### Systems and Components

- `renovate.json`: shared Bake annotation manager and custom datasource definitions.
- `docker/lvm/Dockerfile` and `docker/lvm/docker-bake.json`.

### Data and Integrations

- Renovate reads Wolfi package definitions from the public `wolfi-dev/os` GitHub repository.

### Operational Impact

- A base digest update alone does not change the `lvm` image tag. Its publication follows the repository publication rules for unchanged tags.
- Documentation: `docs/reference/lvm.md` and `docs/reference/dependency-updates.md`.
