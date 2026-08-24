## Purpose

Define the repository workflow for describing, verifying, publishing, tagging, and updating monorepo OCI images from Docker Bake manifests through Dagger and provider CI.

## Requirements

### Requirement: Image directories define Docker Bake targets

Each image directory under `docker/` SHALL define its OCI image build metadata in a local `docker-bake.json` manifest.

#### Scenario: Image target manifest is present

- **WHEN** an image component exists under `docker/<image>`
- **THEN** `docker/<image>/docker-bake.json` defines the Bake target context, Dockerfile, build arguments, publish tags, OCI labels, and platforms for that image

#### Scenario: Hugo autoprefixer target is described

- **WHEN** `docker/hugo-autoprefixer/docker-bake.json` is read
- **THEN** it defines the `hugo-autoprefixer` target using `docker/hugo-autoprefixer` as context, `Dockerfile` as Dockerfile, Hugo and autoprefixer build arguments, OCI labels, platforms, and a publish tag rendered from the configured registry, repository prefix, and dependency versions

### Requirement: Bake variables control image versions and destinations

Bake manifests SHALL keep dependency versions and publication destination defaults in variables.

#### Scenario: Dependency versions render image version

- **WHEN** an image manifest defines dependency version variables
- **THEN** the image version tag is rendered from those variables according to the image's documented versioning scheme

#### Scenario: Registry destination is overridable

- **WHEN** callers provide registry or repository prefix overrides
- **THEN** the resolved image references use those overrides while preserving the image name and version tag

### Requirement: Dagger resolves Bake metadata without building

The reusable Dagger Docker module SHALL resolve supported Docker Bake target metadata without running a container image build.

#### Scenario: Resolve Bake target metadata

- **WHEN** a caller requests metadata for a Bake manifest and target
- **THEN** the Docker module returns the resolved context, Dockerfile, Dockerfile stage when configured, build arguments, platforms, labels, and image references without building an image

#### Scenario: Unsupported Bake fields fail clearly

- **WHEN** a Bake target contains fields not supported by the Dagger resolver
- **THEN** resolution fails with a clear validation error instead of silently ignoring those fields

### Requirement: Dagger builds from resolved Bake targets

The reusable Dagger Docker module SHALL build images from resolved Bake target metadata using Dagger-native build APIs.

#### Scenario: Build reuses metadata resolver

- **WHEN** a caller requests a Bake-driven build
- **THEN** the Docker module resolves the Bake target once and uses that resolved metadata for the Dagger build

#### Scenario: Bake build exposes image references

- **WHEN** a `DockerBuild` is created from a Bake target with publish tags
- **THEN** `DockerBuild.image_refs()` returns the resolved image references and `DockerBuild.tags()` returns the resolved tag values

#### Scenario: Explicit build has no Bake references

- **WHEN** a `DockerBuild` is created without Bake metadata
- **THEN** `DockerBuild.image_refs()` and `DockerBuild.tags()` return empty lists

### Requirement: Container image scenario verifies and publishes Bake targets

The Dagger container-images scenario SHALL expose CI-facing operations for verifying and publishing Bake targets through the Docker module.

#### Scenario: Verify Bake target

- **WHEN** CI or a local caller requests verification for a Bake manifest
- **THEN** the scenario builds the resolved target without publishing an image

#### Scenario: Publish Bake target

- **WHEN** registry authentication is configured and a caller requests publication for a Bake manifest
- **THEN** the scenario builds the resolved target and publishes every resolved image reference

#### Scenario: Select Bake manifest target

- **WHEN** a Bake manifest contains multiple targets
- **THEN** callers provide `bake-target` to select the target

#### Scenario: Select the only Bake manifest target

- **WHEN** a Bake manifest contains exactly one target and callers omit `bake-target`
- **THEN** the scenario selects the only target

### Requirement: Registry authentication is separate from manifests

Registry credentials SHALL be configured at runtime and SHALL NOT be stored in `docker-bake.json`.

#### Scenario: Configure registry auth before publishing

- **WHEN** callers configure one or more registry authentications before publication
- **THEN** the scenario uses those credentials while publishing matching image references

#### Scenario: Bake manifest contains no secrets

- **WHEN** a `docker-bake.json` manifest is committed
- **THEN** it contains destination references and variables but no registry usernames, passwords, or tokens

### Requirement: Provider workflows delegate image operations

GitHub Actions workflows SHALL handle provider events, checkout, permissions, credentials, and target selection while delegating image verification and publication to the Makefile and Dagger.

#### Scenario: Pull request verification

- **WHEN** a pull request changes an image component or shared pipeline configuration
- **THEN** the workflow detects affected `docker/*` components and verifies each affected Bake target through the same Makefile entry point available locally

#### Scenario: Required status aggregation

- **WHEN** pull request verification completes
- **THEN** the workflow exposes an always-run `CI Passed` job that succeeds only when all required verification jobs succeed

#### Scenario: Master branch publication

- **WHEN** a push to `master` changes an image component
- **THEN** the workflow publishes each affected Bake target through the same Makefile entry point available locally

### Requirement: Releases create Git tag markers after publication

Successful image publication SHALL create an idempotent Git release marker tag for the published image version.

#### Scenario: Render release marker from Bake metadata

- **WHEN** a caller requests the release marker for a Bake manifest and component path
- **THEN** the container-images scenario resolves Bake metadata without building an image and returns `<component-path>/<image-version>`

#### Scenario: Ensure release marker tag exists

- **WHEN** the Git module is asked to ensure a release marker tag exists
- **THEN** it returns successfully if the remote tag already exists, or creates and pushes a lightweight tag on `HEAD` if it is missing

### Requirement: Renovate covers operational dependency pins

Renovate SHALL detect and automerge supported updates for operational dependency pins committed in workflows and Bake manifests.

#### Scenario: Workflow dependency update

- **WHEN** newer supported versions of GitHub Actions or Dagger CLI are available
- **THEN** Renovate proposes and automerges updates for the workflow pins

#### Scenario: Daggerverse dependency update

- **WHEN** newer compatible released daggerverse module or scenario tags are available
- **THEN** Renovate proposes and automerges updates for the workflow references

#### Scenario: Image dependency update

- **WHEN** newer supported versions are available for dependencies described by Bake variable Renovate metadata
- **THEN** Renovate proposes and automerges updates to the matching `docker/**/docker-bake.json` variables

#### Scenario: Operational pin audit

- **WHEN** Renovate configuration changes
- **THEN** every committed operational version pin is either covered by a Renovate manager or documented as intentionally unmanaged

### Requirement: LVM image target is described

The repository SHALL describe the `lvm` image with a local Docker Bake target containing its context, Dockerfile, version inputs, publish tag, OCI labels, and validated platforms.

#### Scenario: LVM Bake target is resolved

- **WHEN** `docker/lvm/docker-bake.json` is resolved with default variables
- **THEN** it defines one `lvm` target whose image reference uses the default registry and repository prefix and whose tag is rendered from the exact Wolfi LVM2 package version

### Requirement: LVM image dependency pins are managed

The LVM image Bake manifest SHALL define `WOLFI_BASE_DIGEST` and `LVM_PACKAGE_VERSION` variables, and each managed variable SHALL expose Renovate metadata through its `description` field.

#### Scenario: A supported LVM dependency update is available

- **WHEN** Renovate detects a newer supported base digest or exact Wolfi package version
- **THEN** it proposes an update to the matching variable in `docker/lvm/docker-bake.json`

#### Scenario: Non-version inputs change

- **WHEN** the Wolfi base digest or default command changes without changing `LVM_PACKAGE_VERSION`
- **THEN** the resolved LVM image tag remains unchanged

### Requirement: LVM image verification covers runtime behavior

Verification for the LVM image SHALL validate both the Bake build and the image-specific command behavior required by the LVM image specification.

#### Scenario: Verify LVM image component

- **WHEN** the LVM image component is verified before publication
- **THEN** verification confirms the expected LVM commands and versions are present and the default command remains running

#### Scenario: Validate privileged block-device behavior

- **WHEN** a suitable privileged test environment is available
- **THEN** verification exercises physical volume and volume group creation on a disposable block device without modifying host production storage
