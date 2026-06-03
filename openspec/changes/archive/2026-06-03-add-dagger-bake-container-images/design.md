## Context

The repository currently contains only project metadata and no image build pipeline. A reusable Dagger Docker module exists at `/home/user/code/riftonix/daggerverse/modules/docker`; it already builds explicit Docker contexts and publishes `DockerBuild` objects. A reusable Dagger scenario exists at `/home/user/code/riftonix/daggerverse/scenarios/container-images`; it already verifies and publishes explicit Docker contexts, but callers must provide context paths and image references.

The target model is a monorepo of base OCI images under `docker/`. GitHub Actions must decide when to run, while Dagger owns image verification and publication. Docker Buildx Bake will be used as the standard build manifest format so image targets, arguments, platforms, labels, and tags are not described by a custom YAML schema.

## Goals / Non-Goals

**Goals:**

- Describe image build targets with per-image `docker-bake.json` files under `docker/<image>/`.
- Support a Docker module function that resolves Bake target metadata without building an image.
- Support Docker module functions that build from resolved Bake target metadata and return normal `DockerBuild` objects.
- Support `DockerBuild.image_refs()` and `DockerBuild.tags()` accessors for Bake-derived image references.
- Support container-images scenario functions that verify and publish Bake targets through the Docker module.
- Support a container-images scenario function that renders a Git release marker from resolved Bake metadata without performing Git operations.
- Support separately configured registry authentication in the container-images scenario, including multiple registries before one publish operation.
- Support an idempotent Git module operation that creates and pushes a requested release marker tag.
- Publish `docker/hugo-autoprefixer` as `ghcr.io/riftonix/container-images/hugo-autoprefixer:<hugo-version>-<autoprefixer-version>`.
- Allow the registry and repository prefix to default to `ghcr.io` and `riftonix/container-images` and be overridden independently in CI or local calls.
- Configure Renovate automerge for every operational dependency pin in this repository: Dagger CLI, GitHub Actions, released Dagger modules/scenarios, Hugo, and autoprefixer.
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

### Add Metadata-Only Bake Resolution to the Docker Module

Bake parsing and resolution belongs in the reusable Docker module because it is Docker build metadata, not CI policy. The module will expose `resolve-bake-target(source, bake-path, target=None, variable-overrides=None) -> DockerBakeTarget`. The returned object contains resolved context, Dockerfile, Dockerfile target, args, tags, labels, and platforms without running a container image build.

`build-from-bake` will call `resolve-bake-target` and translate the resolved metadata into the existing Dagger-native `build(...)` call. `DockerBuild` will gain `image_refs()` and `tags()` accessors. Explicit `build(...)` calls return empty lists for these accessors. Bake-derived builds return the resolved Bake tags as image references, and `tags()` returns the tag portion or equivalent resolved tag strings needed by callers.

### Build With Dagger APIs, Not `docker buildx bake --push`

The Docker module will accept `--bake-path`, resolve the Bake target metadata, and translate supported fields into Dagger-native build calls only when a caller requests `build-from-bake`. Metadata consumers can call `resolve-bake-target` without triggering a build. This keeps CI portable and avoids depending on Docker socket access, external Buildx builders, or Buildx CLI auth inside a Dagger container.

The initial supported target fields are `context`, `dockerfile`, `args`, `tags`, `labels`, and `platforms`. Unsupported fields must fail with a clear error instead of being ignored.

### Keep GitHub Actions Thin

GitHub Actions will handle events, checkout, auth variables, and changed target selection. The actual verify/publish operation will be a Dagger scenario call such as `verify-bake-target --bake-path docker/hugo-autoprefixer/docker-bake.json` or `with-registry-auth ... publish-bake-target --bake-path docker/hugo-autoprefixer/docker-bake.json`. The scenario functions should be thin wrappers around `dag.docker().build-from-bake(...)`.

### Configure Registry Authentication Separately From Publication

The container-images scenario will expose a chainable `with-registry-auth(address, username, password)` function. Callers can invoke it multiple times before publication to configure credentials for every required registry. The scenario forwards the accumulated credentials to the Docker module before building and publishing.

`publish-image` keeps an explicit `image-ref` input. Explicit image wrappers keep the optional `target` argument for selecting a Dockerfile stage. Bake wrappers use a required `bake-target` argument for selecting a named Bake manifest target; any Dockerfile stage for a Bake build remains configured inside `docker-bake.json`. `publish-bake-target` publishes every resolved `DockerBuild.image_refs()` value. Neither publish function accepts registry credentials directly.

Registry credentials are runtime secrets supplied by CI, local environment variables, or a secret manager. They must not be stored in `docker-bake.json`. Bake `tags` describe destination image references and may target multiple registries.

### Use Bake Variables for Registry And Repository Overrides

Each per-image `docker-bake.json` will define a `REGISTRY` variable with default `ghcr.io` and a `REPOSITORY_PREFIX` variable with default `riftonix/container-images`. The Docker module Bake function will accept variable overrides and use them while resolving target tags. This allows local testing, forks, repository moves, and future registry migrations without editing the manifest.

### Compose Post-Publish Git Tags With Dagger Shell

The container-images scenario will expose `get-bake-release-tag(source, bake-path, component-path, bake-target=None, variable-overrides=None) -> str`. It calls Docker `resolve-bake-target` without building an image, validates that the resolved image references map to one image version, and returns a release marker in the form `<component-path>/<image-version>`, for example `docker/hugo-autoprefixer/0.147.1-10.4.21`. The component path is explicit because a Bake file may be supplied from an arbitrary source layout. The function does not receive Git credentials or perform Git operations.

The reusable Git module will expose `ensure-pushed-tag(tag, remote="origin") -> str`. It fetches remote tags, returns successfully when the requested tag already exists, and otherwise creates a lightweight tag on `HEAD` and pushes it. Authentication remains configured through the Git module's existing `with-https-token-auth` function.

The publish workflow will use one Dagger Shell invocation after checkout: first publish the resolved image references through the container-images scenario, then render the release marker through `get-bake-release-tag`, then pass that string to the Git module's authenticated `ensure-pushed-tag`. Tags are release markers, not publication triggers. This keeps image-specific metadata in the image scenario, generic Git release behavior in the Git module, and provider-specific credentials in GitHub Actions.

### Store Hugo Versions in Bake Variables

For `hugo-autoprefixer`, Bake variables will hold `HUGO_VERSION` and `AUTOPREFIXER_VERSION`. The target tag will render `${REGISTRY}/${REPOSITORY_PREFIX}/hugo-autoprefixer:${HUGO_VERSION}-${AUTOPREFIXER_VERSION}` and pass the same values as Docker build args.

Renovate will update these variables using custom managers or JSON-compatible extraction, and the Dockerfile will consume the args.

### Cover All Operational Version Pins With Renovate

Renovate will extend the daggerverse automerge policy and cover every operational version pin committed in this repository:

- rely on Renovate's default built-in `github-actions` manager for workflow `uses:` references such as `actions/checkout` and `dagger/dagger-for-github`; no custom manager is needed for these pins
- use the same Dagger CI custom datasource and regex manager pattern as daggerverse for `DAGGER_VERSION` in `.github/workflows/*.yaml`
- use a regex custom manager with GitHub tags for released daggerverse refs such as `github.com/riftonix/daggerverse/modules/git@modules/git/v1.0.1` and `github.com/riftonix/daggerverse/scenarios/container-images@scenarios/container-images/v0.1.2`
- use Renovate metadata in `docker/**/docker-bake.json` variable descriptions for image-specific dependencies such as `hugomods/hugo` and `autoprefixer`

Version strings used only as explanatory OpenSpec examples are not operational pins and must not be updated as dependencies. After adding the configuration, audit the repository's committed operational pins against Renovate coverage so future uncategorized pins are visible.

`REGISTRY` and `REPOSITORY_PREFIX` Bake defaults are runtime configuration, not dependency versions, and are intentionally unmanaged. The Docker Dagger module is consumed transitively through the released container-images scenario, so this repository has no direct `modules/docker` pin to update.

## Risks / Trade-offs

- Bake feature coverage is partial -> fail clearly on unsupported fields in the Docker module and add support only when needed.
- Bake parsing could be duplicated between metadata and build consumers -> centralize parsing and interpolation in `resolve-bake-target`, then implement `build-from-bake` on top of the resolved object.
- JSON Bake is less ergonomic than HCL -> prefer machine-readability because Dagger must resolve it without Docker CLI.
- Renovate custom managers can silently miss non-standard pins -> annotate Bake variables, add focused regex managers for Dagger CLI and daggerverse refs, and audit every operational pin after configuration.
- Git tag creation can race if the same version is republished -> keep `ensure-pushed-tag` idempotent for an existing remote tag and fail clearly if a concurrent conflicting push occurs.
- Updating external Dagger modules/scenarios may require a coordinated daggerverse change -> implement and test the Docker module first, then update the scenario wrapper, then consume it from this repository.
- Publishing to multiple private registries requires separate credentials -> configure one or more chainable scenario registry auth entries before publication and keep secrets outside Bake manifests.
