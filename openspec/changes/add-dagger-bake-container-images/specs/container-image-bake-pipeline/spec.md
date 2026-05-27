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

### Requirement: DockerBuild exposes Bake image references

The reusable Dagger Docker module SHALL expose resolved image references and tags from `DockerBuild`.

#### Scenario: Access Bake image references

- **WHEN** a `DockerBuild` is created from the `hugo-autoprefixer` Bake target
- **THEN** `DockerBuild.image_refs()` includes `ghcr.io/riftonix/container-images/hugo-autoprefixer:<hugo-version>-<autoprefixer-version>`

#### Scenario: Explicit build has no image references

- **WHEN** a `DockerBuild` is created from an explicit Docker context without Bake metadata
- **THEN** `DockerBuild.image_refs()` and `DockerBuild.tags()` return empty lists

### Requirement: Dagger scenario verifies Bake targets

The Dagger container-images scenario SHALL provide a function that verifies an image by Bake path and target name using Dagger-native build APIs.

#### Scenario: Verify Hugo target

- **WHEN** CI requests verification of the `hugo-autoprefixer` Bake target with bake path `docker/hugo-autoprefixer/docker-bake.json`
- **THEN** the scenario builds the target through the Docker module and reports success without publishing an image

### Requirement: Dagger scenario publishes Bake targets

The Dagger container-images scenario SHALL provide a function that publishes an image by Bake path and target name using Dagger-native publish APIs.

#### Scenario: Publish Hugo target

- **WHEN** CI requests publication of the `hugo-autoprefixer` Bake target with bake path `docker/hugo-autoprefixer/docker-bake.json` and GHCR credentials
- **THEN** the scenario builds the target through the Docker module, publishes the resolved `DockerBuild.image_refs()`, and returns the published image reference

### Requirement: Registry prefix is overridable

The publish pipeline SHALL default the registry/repository prefix to `ghcr.io/riftonix/container-images` and SHALL allow callers to override it.

#### Scenario: Publish to alternate registry

- **WHEN** a caller provides a registry override while publishing the `hugo-autoprefixer` target
- **THEN** the image reference uses the override prefix and keeps the same image name and version tag

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

#### Scenario: Main branch publication

- **WHEN** a push to the main branch changes the `hugo-autoprefixer` target or its context
- **THEN** the workflow calls Dagger to publish the affected Bake target

### Requirement: Releases create git tag markers after publish

The publish workflow SHALL create a git tag after successful image publication.

#### Scenario: Create post-publish tag

- **WHEN** `hugo-autoprefixer` version `0.147.1-10.4.21` is published successfully
- **THEN** the workflow creates tag `docker/hugo-autoprefixer/0.147.1-10.4.21`

### Requirement: Renovate updates Hugo image dependencies

Renovate SHALL detect and automerge supported Hugo and autoprefixer version updates used by the `hugo-autoprefixer` Bake target.

#### Scenario: Hugo version update

- **WHEN** a newer compatible `hugomods/hugo:exts-*` tag is available
- **THEN** Renovate opens and automerges a pull request updating the Hugo version used by the Bake target

#### Scenario: Autoprefixer version update

- **WHEN** a newer compatible `autoprefixer` npm version is available
- **THEN** Renovate opens and automerges a pull request updating the autoprefixer version used by the Bake target
