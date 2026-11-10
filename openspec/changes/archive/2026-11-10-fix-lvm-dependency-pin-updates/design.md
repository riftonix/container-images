# Fix LVM Dependency Pin Updates Design

## Glossary and References

### Glossary

- **Bake annotation**: a `description` value of a Bake variable in the form `renovate: datasource=<datasource> depName=<dependency> [versioning=<scheme>] [extractVersion=<regex>]`, read by the shared regex manager in `renovate.json`.
- **Epoch**: the Wolfi package definition field that becomes the apk revision, so `version: "2.03.44"` with `epoch: 1` is installed as `2.03.44-r1`.

### References

- Wolfi package definition for `lvm2`: `https://raw.githubusercontent.com/wolfi-dev/os/main/lvm2.yaml`
- Renovate custom datasources: `https://docs.renovatebot.com/modules/datasource/custom/`
- Renovate Dockerfile manager: `https://docs.renovatebot.com/modules/manager/dockerfile/`

## Context

### Problem Context

See proposal.md, Why. The Dependency Dashboard shows no dependencies from `docker/lvm/`, and the `lvm2` pin has not changed since the image was added.

### Existing Technical Constraints

- The shared Bake annotation regex captures the datasource with `[a-z-]+`, which cannot match `custom.wolfi`.
- `renovate.json` has no `customDatasources` section.
- The Wolfi package repository publishes its current index only as `APKINDEX.tar.gz`. Renovate custom datasources accept `json`, `plain`, `yaml`, `html`, and `toml`, not archives. The `APKINDEX.json` file next to it is not maintained; its newest build dates from January 2024 and lists `lvm2` `2.03.23-r1`.
- Repology does not list a Wolfi repository for `lvm2`.
- The Dockerfile manager handles literal `FROM <image>:<tag>@<digest>` references, as already used by `docker/ngate-client/Dockerfile` and `docker/updatecli-python-nodejs/Dockerfile`. It skips references built from `ARG` values.
- The repository uses the hosted Renovate app, so `postUpgradeTasks` are not available.

## Goals / Non-Goals

### Goals

- Use only Renovate features available in the hosted app.
- Keep one annotation format for all Bake variables.

### Non-Goals

- Track older or alternative Wolfi package versions; only the latest definition is needed.
- Add a Wolfi datasource for packages other than those annotated in Bake manifests.

## Component Changes

### `renovate.json`

- Both Bake annotation match strings capture the datasource with `[a-z.-]+`.
- A `customDatasources.wolfi` entry reads `https://raw.githubusercontent.com/wolfi-dev/os/main/{{packageName}}.yaml` in `yaml` format and transforms it with JSONata into one release whose version is `package.version`, `-r`, and `package.epoch`.

### `docker/lvm/Dockerfile`

- The `WOLFI_BASE_DIGEST` build argument is removed.
- The base image is `docker.io/chainguard/wolfi-base:latest@sha256:<digest>`, starting from the digest currently stored in `WOLFI_BASE_DIGEST`.

### `docker/lvm/docker-bake.json`

- The `WOLFI_BASE_DIGEST` variable and build argument are removed.
- `org.opencontainers.image.base.name` becomes `docker.io/chainguard/wolfi-base:latest`.
- `LVM_PACKAGE_VERSION` and its annotation `datasource=custom.wolfi depName=lvm2 versioning=loose` stay unchanged.

### Documentation

- `docs/reference/lvm.md`: base image line, build arguments, and Renovate metadata table.
- `docs/reference/dependency-updates.md`: the `lvm` variable table and the `custom.wolfi` datasource description.

## Technical Contracts

### External Integrations

- Renovate fetches `<package>.yaml` from the `main` branch of `wolfi-dev/os` without authentication. The transform requires `package.version` and `package.epoch` to be present.
- The Dockerfile manager resolves the digest of `docker.io/chainguard/wolfi-base:latest` from Docker Hub.

## Decisions

### Decision: Read versions from the Wolfi package definition

The definition in `wolfi-dev/os` is the only maintained, Renovate-readable source that contains both the version and the epoch.

Alternatives considered:

- `APKINDEX.json` from `packages.wolfi.dev`: readable as JSON but no longer updated.
- `APKINDEX.tar.gz`: current, but archives are not a supported custom datasource format.
- Repology: no Wolfi repository for `lvm2`, and its versions do not carry the apk revision.

### Decision: Pin the base image in the Dockerfile

A literal tag and digest reference is handled natively by the Dockerfile manager, matches the other images in the repository, and needs no Renovate digest support in the Bake annotation format.

Alternatives considered:

- Keep `WOLFI_BASE_DIGEST` and add a digest-specific match string. The annotation format has no tag for the digest, and excluding `sha256:` values from the existing match strings would need lookahead, which the regex engine used by Renovate does not support.

### Decision: Widen the datasource pattern instead of renaming the datasource

`custom.<name>` is the naming Renovate requires for repository-defined datasources, so the pattern must accept dots.

## Risks / Trade-offs

- [A version is defined in `wolfi-dev/os` before its package is published] → the Renovate pull request fails `apk add` in CI and is not automerged until the package exists and CI is re-run.
- [The `wolfi-dev/os` file layout or field names change] → the datasource lookup fails and is reported on the Dependency Dashboard; the transform is adjusted then.
- [The JSONata transform cannot be validated without running Renovate] → the first Renovate run after merge confirms it through the Dependency Dashboard and an `lvm2` update proposal.
- [Base digest updates do not change the image tag] → they are verified by CI and published according to the repository rules for existing release tags.

## Migration Plan

### Rollout

1. Merge the change to `master`.
2. Confirm that the Dependency Dashboard lists `lvm2` from `docker/lvm/docker-bake.json` and `docker.io/chainguard/wolfi-base` from `docker/lvm/Dockerfile`.
3. Let Renovate propose the `lvm2` update.

### Backward Compatibility

The published image and its tag do not change with this change. Bake overrides of `WOLFI_BASE_DIGEST` stop having an effect.

### Rollback

Revert the commit. The previous configuration did not update the `lvm` dependencies, so reverting restores the earlier state without other side effects.
