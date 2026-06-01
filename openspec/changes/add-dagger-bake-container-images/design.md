## Context

The repository currently contains only project metadata and no image build pipeline. A reusable Dagger Docker module exists at `/home/user/code/riftonix/daggerverse/modules/docker`; it already builds explicit Docker contexts and publishes `DockerBuild` objects. A reusable Dagger scenario exists at `/home/user/code/riftonix/daggerverse/scenarios/container-images`; it already verifies and publishes explicit Docker contexts, but callers must provide context paths and image references.

The target model is a monorepo of base OCI images under `docker/`. GitHub Actions must decide when to run, while Dagger owns image verification and publication. Docker Buildx Bake will be used as the standard build manifest format so image targets, arguments, platforms, labels, and tags are not described by a custom YAML schema.

## Goals / Non-Goals

**Goals:**

- Describe image build targets with per-image `docker-bake.json` files under `docker/<image>/`.
- Support Docker module functions that build from Bake target names and return normal `DockerBuild` objects.
- Support `DockerBuild.image_refs()` and `DockerBuild.tags()` accessors for Bake-derived image references.
- Support container-images scenario functions that verify and publish Bake targets through the Docker module.
- Support separately configured registry authentication in the container-images scenario, including multiple registries before one publish operation.
- Publish `docker/hugo-autoprefixer` as `ghcr.io/riftonix/container-images/hugo-autoprefixer:<hugo-version>-<autoprefixer-version>`.
- Allow the registry and repository prefix to default to `ghcr.io` and `riftonix/container-images` and be overridden independently in CI or local calls.
- Configure Renovate automerge for Hugo and autoprefixer version updates.
- Create git release marker tags after successful publication.

**Non-Goals:**

- Running `docker buildx bake --push` as the primary build backend.
- Introducing apko/melange packaging for the Hugo image.
- Building a generic release bot or changelog generator.
- Publishing images before a successful main-branch build.

## Decisions

### Use Per-Image Docker Buildx Bake JSON as the Manifest

Use `docker/<image>/docker-bake.json` instead of a custom `image.yaml`. Bake is a Docker-native build description format and supports JSON, which is straightforward for Dagger/Python code to parse. Keeping the Bake file inside each image directory makes each image self-contained and keeps versions, Dockerfile, and target metadata together.

Alternatives considered:

- Custom `image.yaml`: expressive but project-specific.
- Compose YAML: standard, but less direct for per-target release tag logic.
- Bake HCL: ergonomic for humans, but harder to parse without invoking Docker tooling.

### Add Bake Support to the Docker Module

Bake parsing and resolution belongs in the reusable Docker module because it is Docker build metadata, not CI policy. The module will expose a function such as `build-from-bake` that accepts `source`, `bake-path`, `target`, and optional variable overrides. It will return the existing `DockerBuild` object so smoke checks, dry-run publication, registry auth, and `publish` remain unchanged.

`DockerBuild` will gain `image_refs()` and `tags()` accessors. Explicit `build(...)` calls return empty lists for these accessors. Bake-derived builds return the resolved Bake tags as image references, and `tags()` returns the tag portion or equivalent resolved tag strings needed by callers.

### Build With Dagger APIs, Not `docker buildx bake --push`

The Docker module will accept `--bake-path`, parse the Bake target from that file, and translate supported fields into Dagger-native build calls. This keeps CI portable and avoids depending on Docker socket access, external Buildx builders, or Buildx CLI auth inside a Dagger container.

The initial supported target fields are `context`, `dockerfile`, `args`, `tags`, `labels`, and `platforms`. Unsupported fields must fail with a clear error instead of being ignored.

### Keep GitHub Actions Thin

GitHub Actions will handle events, checkout, auth variables, and changed target selection. The actual verify/publish operation will be a Dagger scenario call such as `verify-bake-target --bake-path docker/hugo-autoprefixer/docker-bake.json` or `with-registry-auth ... publish-bake-target --bake-path docker/hugo-autoprefixer/docker-bake.json`. The scenario functions should be thin wrappers around `dag.docker().build-from-bake(...)`.

### Configure Registry Authentication Separately From Publication

The container-images scenario will expose a chainable `with-registry-auth(address, username, password)` function. Callers can invoke it multiple times before publication to configure credentials for every required registry. The scenario forwards the accumulated credentials to the Docker module before building and publishing.

`publish-image` keeps an explicit `image-ref` input. Explicit image wrappers keep the optional `target` argument for selecting a Dockerfile stage. Bake wrappers use a required `bake-target` argument for selecting a named Bake manifest target; any Dockerfile stage for a Bake build remains configured inside `docker-bake.json`. `publish-bake-target` publishes every resolved `DockerBuild.image_refs()` value. Neither publish function accepts registry credentials directly.

Registry credentials are runtime secrets supplied by CI, local environment variables, or a secret manager. They must not be stored in `docker-bake.json`. Bake `tags` describe destination image references and may target multiple registries.

### Use Bake Variables for Registry And Repository Overrides

Each per-image `docker-bake.json` will define a `REGISTRY` variable with default `ghcr.io` and a `REPOSITORY_PREFIX` variable with default `riftonix/container-images`. The Docker module Bake function will accept variable overrides and use them while resolving target tags. This allows local testing, forks, repository moves, and future registry migrations without editing the manifest.

### Use Post-Publish Git Tags

The publish workflow will create `docker/hugo-autoprefixer/<tag>` only after Dagger successfully publishes the image. Tags are release markers, not the trigger for publication. This avoids relying on tag-created workflows from bot-created tags.

### Store Hugo Versions in Bake Variables

For `hugo-autoprefixer`, Bake variables will hold `HUGO_VERSION` and `AUTOPREFIXER_VERSION`. The target tag will render `${REGISTRY}/${REPOSITORY_PREFIX}/hugo-autoprefixer:${HUGO_VERSION}-${AUTOPREFIXER_VERSION}` and pass the same values as Docker build args.

Renovate will update these variables using custom managers or JSON-compatible extraction, and the Dockerfile will consume the args.

## Risks / Trade-offs

- Bake feature coverage is partial -> fail clearly on unsupported fields in the Docker module and add support only when needed.
- JSON Bake is less ergonomic than HCL -> prefer machine-readability because Dagger must resolve it without Docker CLI.
- Renovate may need custom regex for JSON variables -> keep variable names stable and add focused package rules.
- Git tag creation can race if the same version is republished -> make tag creation idempotent or fail with a clear "already released" message after confirming the image exists.
- Updating external Dagger modules/scenarios may require a coordinated daggerverse change -> implement and test the Docker module first, then update the scenario wrapper, then consume it from this repository.
- Publishing to multiple private registries requires separate credentials -> configure one or more chainable scenario registry auth entries before publication and keep secrets outside Bake manifests.
