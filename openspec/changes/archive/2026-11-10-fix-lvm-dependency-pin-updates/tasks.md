## 1. Renovate Configuration

- [x] 1.1 Capture the datasource with `[a-z.-]+` in both Bake annotation match strings of `renovate.json`, and verify with a local regex check that `docker/lvm/docker-bake.json` yields `lvm2` with datasource `custom.wolfi` and that the annotations of the other Bake manifests are matched as before.
- [x] 1.2 Add `customDatasources.wolfi` to `renovate.json` with the `wolfi-dev/os` package definition URL, `yaml` format, and the version and epoch transform, and verify that `renovate.json` parses as JSON and the current `lvm2.yaml` provides `package.version` and `package.epoch`.

## 2. LVM Image Component

- [x] 2.1 Replace the `WOLFI_BASE_DIGEST` build argument in `docker/lvm/Dockerfile` with `FROM docker.io/chainguard/wolfi-base:latest@<current digest>`, and verify that the digest equals the previous `WOLFI_BASE_DIGEST` default and no `ARG WOLFI_BASE_DIGEST` remains.
- [x] 2.2 Remove the `WOLFI_BASE_DIGEST` variable and build argument from `docker/lvm/docker-bake.json` and set `org.opencontainers.image.base.name` to `docker.io/chainguard/wolfi-base:latest`, and verify with `docker buildx bake -f docker/lvm/docker-bake.json lvm --print` that the tag is still `lvm:2.03.42-r1` and no `WOLFI_BASE_DIGEST` argument is rendered.
- [x] 2.3 Provide `make verify docker/lvm` as a user-run command and record its result before merge. Passed in [PR #101 CI](https://github.com/riftonix/container-images/actions/runs/42786154837/job/129728171317); the local attempt could not run because Dagger was not installed.

## 3. Documentation

- [x] 3.1 Update the base image line, build arguments table, and Renovate metadata table in `docs/reference/lvm.md`, and verify that no `WOLFI_BASE_DIGEST` reference remains in `docs/`.
- [x] 3.2 Update the `lvm` variable table and the `custom.wolfi` datasource description in `docs/reference/dependency-updates.md`, and verify that relative links in the changed pages resolve.

## 4. Validation

- [x] 4.1 Run `openspec validate fix-lvm-dependency-pin-updates --strict` and verify that it passes.
- [x] 4.2 After merge, verify that the Dependency Dashboard lists `lvm2` from `docker/lvm/docker-bake.json` and `docker.io/chainguard/wolfi-base` from `docker/lvm/Dockerfile`, and that Renovate proposes an `lvm2` update. Confirmed on 2026-11-10 in the [Dependency Dashboard](https://github.com/riftonix/container-images/issues/9), [base digest PR #102](https://github.com/riftonix/container-images/pull/102), and [lvm2 update PR #103](https://github.com/riftonix/container-images/pull/103).
