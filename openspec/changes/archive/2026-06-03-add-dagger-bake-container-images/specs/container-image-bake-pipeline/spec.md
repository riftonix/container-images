## ADDED Requirements

### Requirement: Docker Bake manifest defines image targets

Each image directory SHALL use a local `docker-bake.json` file to define its OCI image build target.

#### Scenario: Hugo target is described

- **WHEN** the `docker/hugo-autoprefixer/docker-bake.json` manifest is read
- **THEN** it contains a target for `hugo-autoprefixer` with context `docker/hugo-autoprefixer`, Dockerfile `Dockerfile`, build arguments for Hugo and autoprefixer versions, OCI labels, platforms, and a publish tag template

### Requirement: Docker module builds from Bake targets

The reusable Dagger Docker module SHALL provide a function that builds an image from a Bake path and target name using Dagger-native build APIs.

#### Scenario: Build Hugo target from Bake

- **WHEN** a caller requests a Docker module build for target `hugo-autoprefixer` with bake path `docker/hugo-autoprefixer/docker-bake.json`
- **THEN** the Docker module resolves the target from that Bake file and returns a `DockerBuild` configured with the resolved context, Dockerfile, args, platforms, labels, and image references

### Requirement: Docker module resolves Bake metadata without building

The reusable Dagger Docker module SHALL expose resolved Bake target metadata without running a container image build.

#### Scenario: Resolve Hugo target metadata

- **WHEN** a caller requests Docker module metadata for target `hugo-autoprefixer` with bake path `docker/hugo-autoprefixer/docker-bake.json`
- **THEN** `resolve-bake-target` returns the resolved context, Dockerfile, args, platforms, labels, and image references without building an image

#### Scenario: Build reuses resolved metadata

- **WHEN** a caller requests `build-from-bake`
- **THEN** the Docker module uses the same `resolve-bake-target` parser and interpolation behavior before running the Dagger-native build

### Requirement: DockerBuild exposes Bake image references

The reusable Dagger Docker module SHALL expose resolved image references and tags from `DockerBuild`.

#### Scenario: Access Bake image references

- **WHEN** a `DockerBuild` is created from the `hugo-autoprefixer` Bake target
- **THEN** `DockerBuild.image_refs()` includes `ghcr.io/riftonix/container-images/hugo-autoprefixer:<hugo-version>-<autoprefixer-version>`

#### Scenario: Explicit build has no image references

- **WHEN** a `DockerBuild` is created from an explicit Docker context without Bake metadata
- **THEN** `DockerBuild.image_refs()` and `DockerBuild.tags()` return empty lists

### Requirement: Dagger scenario verifies Bake targets

The Dagger container-images scenario SHALL provide a function that verifies an image by Bake path and explicitly named Bake target using Dagger-native build APIs.

#### Scenario: Verify Hugo target

- **WHEN** CI requests verification of the `hugo-autoprefixer` Bake target with bake path `docker/hugo-autoprefixer/docker-bake.json`
- **THEN** the scenario builds the target through the Docker module and reports success without publishing an image

### Requirement: Dagger scenario publishes Bake targets

The Dagger container-images scenario SHALL provide a function that publishes all resolved image references by Bake path and target name using Dagger-native publish APIs.

#### Scenario: Publish Hugo target

- **WHEN** CI configures GHCR credentials and requests publication of the `hugo-autoprefixer` Bake target with bake path `docker/hugo-autoprefixer/docker-bake.json`
- **THEN** the scenario builds the target through the Docker module, publishes every resolved `DockerBuild.image_refs()` value, and returns the published image references

### Requirement: Bake wrapper target input is explicit

The Dagger container-images scenario SHALL allow callers to omit `bake-target` when a Bake manifest contains exactly one target and SHALL require `bake-target` for selecting among multiple named Bake manifest targets. Explicit image wrappers SHALL keep the optional `target` input for selecting a Dockerfile stage.

#### Scenario: Select Bake manifest target

- **WHEN** a caller invokes `verify-bake-target` or `publish-bake-target` for a manifest with multiple targets
- **THEN** the caller provides `bake-target` to select the named entry from `docker-bake.json`

#### Scenario: Select the only Bake manifest target

- **WHEN** a caller invokes `verify-bake-target` or `publish-bake-target` for a manifest with exactly one target and omits `bake-target`
- **THEN** the scenario selects the only named entry from `docker-bake.json`

#### Scenario: Configure Dockerfile stage for Bake build

- **WHEN** a Bake-driven image requires a specific Dockerfile stage
- **THEN** the stage is configured by the target metadata inside `docker-bake.json`

### Requirement: Registry authentication is configured separately from publication

The Dagger container-images scenario SHALL allow callers to configure one or more registry authentications before invoking publication functions. Registry credentials SHALL remain outside `docker-bake.json`.

#### Scenario: Publish explicit image with configured registry auth

- **WHEN** a caller configures registry credentials and publishes an explicit image reference
- **THEN** the scenario publishes the explicit image using the configured credentials

#### Scenario: Publish Bake target to multiple authenticated registries

- **WHEN** a caller configures credentials for multiple registries and publishes a Bake target whose tags reference those registries
- **THEN** the scenario publishes every resolved image reference using the configured credentials

#### Scenario: Bake manifest does not store registry credentials

- **WHEN** a per-image `docker-bake.json` manifest is committed
- **THEN** it contains destination tags and variables but does not contain registry usernames, passwords, or tokens

### Requirement: Registry prefix is overridable

The publish pipeline SHALL default the registry to `ghcr.io` and the repository prefix to `riftonix/container-images`, and SHALL allow callers to override them independently.

#### Scenario: Publish to alternate registry

- **WHEN** a caller provides registry or repository prefix overrides while publishing the `hugo-autoprefixer` target
- **THEN** the image reference uses the overrides and keeps the same image name and version tag

### Requirement: Hugo image version follows dependency versions

The `hugo-autoprefixer` image tag SHALL use `<hugo-version>-<autoprefixer-version>` rendered from Bake variables.

#### Scenario: Render Hugo image tag

- **WHEN** `HUGO_VERSION` is `0.147.1` and `AUTOPREFIXER_VERSION` is `10.4.21`
- **THEN** the image tag is `0.147.1-10.4.21`

### Requirement: GitHub Actions delegate image operations to Dagger

GitHub Actions workflows SHALL trigger on repository events and SHALL delegate image verification and publication to Dagger scenario functions.

#### Scenario: Pull request verification

- **WHEN** a pull request changes `docker/hugo-autoprefixer/**`, workflow files, or Renovate configuration
- **THEN** the workflow calls Dagger to verify the affected Bake target

#### Scenario: Pull request required status aggregation

- **WHEN** the pull request workflow completes
- **THEN** it exposes an always-run `CI Passed` job that succeeds only when all required verification jobs succeed

#### Scenario: Main branch publication

- **WHEN** a push to the main branch changes the `hugo-autoprefixer` target or its context
- **THEN** the workflow calls Dagger to publish the affected Bake target

### Requirement: Releases create git tag markers after publish

The publish workflow SHALL create a git tag after successful image publication by composing Dagger modules in one Dagger Shell invocation.

#### Scenario: Create post-publish tag

- **WHEN** `hugo-autoprefixer` version `0.147.1-10.4.21` is published successfully
- **THEN** the workflow renders and pushes tag `docker/hugo-autoprefixer/0.147.1-10.4.21` through one Dagger Shell invocation

### Requirement: Dagger scenario renders Bake release markers

The Dagger container-images scenario SHALL render a Git release marker from resolved Bake metadata without performing Git operations or building an image.

#### Scenario: Render Hugo release marker

- **WHEN** a caller requests the release marker for `docker/hugo-autoprefixer/docker-bake.json`
- **THEN** `get-bake-release-tag` uses Docker `resolve-bake-target` and returns `docker/hugo-autoprefixer/0.147.1-10.4.21` without building an image

### Requirement: Git module ensures pushed tags

The reusable Dagger Git module SHALL provide an authenticated, provider-neutral operation that ensures a requested Git tag exists on the remote.

#### Scenario: Push missing release tag

- **WHEN** `ensure-pushed-tag` is called for a tag that does not exist on the remote
- **THEN** the Git module creates a lightweight tag on `HEAD`, pushes it to the remote, and returns the tag name

#### Scenario: Accept existing release tag

- **WHEN** `ensure-pushed-tag` is called for a tag that already exists on the remote
- **THEN** the Git module returns the tag name without creating or pushing a duplicate tag

### Requirement: Renovate updates operational dependency pins

Renovate SHALL detect and automerge supported updates for every operational dependency pin committed in workflows and Bake manifests.

#### Scenario: Dagger CLI update

- **WHEN** a newer supported Dagger CLI version is available
- **THEN** Renovate opens and automerges a pull request updating `DAGGER_VERSION` in `ci.yaml` and `publish.yaml`

#### Scenario: GitHub Actions update

- **WHEN** a newer supported GitHub Action version is available
- **THEN** Renovate opens and automerges a pull request updating workflow `uses:` references through its default built-in GitHub Actions manager without custom manager configuration

#### Scenario: Released daggerverse dependency update

- **WHEN** a newer compatible daggerverse module or scenario tag is available
- **THEN** Renovate opens and automerges a pull request updating matching released daggerverse refs in workflows

#### Scenario: Hugo version update

- **WHEN** a newer compatible `hugomods/hugo:exts-*` tag is available
- **THEN** Renovate opens and automerges a pull request updating the Hugo version used by the Bake target

#### Scenario: Autoprefixer version update

- **WHEN** a newer compatible `autoprefixer` npm version is available
- **THEN** Renovate opens and automerges a pull request updating the autoprefixer version used by the Bake target

#### Scenario: Operational pin audit

- **WHEN** Renovate configuration is changed
- **THEN** every committed operational version pin is either covered by a Renovate manager or explicitly documented as intentionally unmanaged

## Implementation Notes (Task 1.1)

- **Docker Module:** Add `build_from_bake(self, source, bake_path, target)` method to the `Docker` class.
- **JSON Parsing:** Use the standard `json` library to parse `docker-bake.json`.
- **Target Resolution:** Implement basic parsing to extract `context` and `dockerfile` fields from the specified target.
- **Testing:** Add new test cases to `daggerverse/modules/docker/tests/src/tests/main.py` (next to existing `build` tests) to verify loading Bake targets from explicit paths.
