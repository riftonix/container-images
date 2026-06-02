## 1. Docker Module Bake Support

- [x] 1.1 Add Docker module `build-from-bake` support and parser/resolver support for per-image `docker-bake.json` targets, with tests for loading Bake targets from an explicit path.
- [x] 1.2 Resolve Bake variables and target interpolation for supported fields: `context`, `dockerfile`, `args`, `tags`, `labels`, and `platforms`, with tests for interpolation, tag rendering, and registry override rendering.
- [x] 1.3 Add clear validation errors for missing bake files, missing targets, missing tags, unsupported target fields, and unsupported interpolation, with tests for validation failures.
- [x] 1.4 Add `DockerBuild.image_refs()` and `DockerBuild.tags()` accessors for Bake-derived image references, with tests for Bake builds and explicit builds.
- [x] 1.5 Ensure Bake-derived `DockerBuild.publish()` can publish the resolved image references, with tests for dry-run publication and registry auth validation.

## 2. Container Images Scenario

- [x] 2.1 Add `verify-bake-target` scenario function that calls Docker module `build-from-bake` and builds the resolved target without publishing, with tests for verification behavior.
- [x] 2.2 Add chainable `with-registry-auth` scenario function that accumulates registry credentials and forwards them to the Docker module, with tests for one and multiple registries.
- [x] 2.3 Ensure existing `publish-image` uses separately configured registry auth and retains its explicit `image-ref` input, with tests.
- [x] 2.4 Add `publish-bake-target` scenario function that calls Docker module `build-from-bake` and publishes all resolved `DockerBuild.image_refs()` values using separately configured registry auth, with dry-run tests.
- [x] 2.5 Rename the Bake wrapper target selector from `target` to `bake-target` for `verify-bake-target` and `publish-bake-target`, keeping explicit image `target` as the optional Dockerfile stage selector, with tests and documentation updates.

## 3. Hugo Autoprefixer Image

- [x] 3.1 Create `docker/hugo-autoprefixer/Dockerfile` based on `hugomods/hugo:exts-${HUGO_VERSION}`.
- [x] 3.2 Install `autoprefixer@${AUTOPREFIXER_VERSION}` in the image.
- [x] 3.3 Add OCI labels for title, version, source, base image, and component versions.
- [x] 3.4 Add `docker/hugo-autoprefixer/docker-bake.json` with `REGISTRY`, `REPOSITORY_PREFIX`, `HUGO_VERSION`, and `AUTOPREFIXER_VERSION` variables.
- [x] 3.5 Define the `hugo-autoprefixer` Bake target with tag `${REGISTRY}/${REPOSITORY_PREFIX}/hugo-autoprefixer:${HUGO_VERSION}-${AUTOPREFIXER_VERSION}`.

## 4. GitHub Actions

- [x] 4.1 Add PR workflow with an always-run `CI Passed` aggregation job so the repository's required status check is available before merging to `master`.
- [x] 4.2 Add Bake target discovery and verification jobs that call Dagger `verify-bake-target`, pinning the external scenario to `scenarios/container-images/v0.1.1`, and require their success from `CI Passed`.
- [x] 4.3 Use the pinned Git module `modules/git/v1.0.0` from the PR workflow to select changed `docker/*` components for the GitHub verification matrix.
- [x] 4.4 Update the `container-images` scenario so `bake-target` is optional when a Bake manifest contains exactly one target, then simplify provider workflows to pass only the Bake path.
- [x] 4.5 Add main-branch publish workflow that calls Dagger `publish-bake-target` with GHCR credentials.
- [x] 4.6 Ensure workflows request only required permissions for contents, packages, and pull requests.

## 5. Dagger Shell Git Release Tags

- [x] 5.1 Refactor the reusable Docker module to expose metadata-only `resolve-bake-target`, reuse it from `build-from-bake`, and add Docker module tests proving metadata resolution does not require a build.
- [x] 5.2 Add `get-bake-release-tag` to the `container-images` scenario: use Docker `resolve-bake-target` and render the release marker `<component-path>/<image-version>` without performing Git operations or building an image; add container-images scenario tests for the rendered Hugo marker.
- [x] 5.3 Add provider-neutral `ensure-pushed-tag` to the reusable Git module using its existing authentication configuration; add Git module tests for newly created and existing remote tags.
- [x] 5.4 Update the main-branch publish workflow to run publication, `get-bake-release-tag`, and authenticated Git `ensure-pushed-tag` sequentially through one Dagger Shell invocation.
- [x] 5.5 Grant the publish workflow `contents: write` for post-publish Git tags while retaining only the required package publication permission.

## 6. Renovate

- [x] 6.1 Add Renovate base configuration extending the existing daggerverse automerge policy and verify that the default built-in GitHub Actions manager remains enabled for workflow `uses:` references without custom manager configuration.
- [x] 6.2 Add the daggerverse-style Dagger CI custom datasource and regex manager so Renovate updates `DAGGER_VERSION` together in `.github/workflows/ci.yaml` and `.github/workflows/publish.yaml`.
- [x] 6.3 Add a regex custom manager for released daggerverse workflow refs, covering `modules/git@modules/git/v*` and `scenarios/container-images@scenarios/container-images/v*` tags.
- [x] 6.4 Add a generic Renovate custom manager for `docker/**/docker-bake.json` variables whose `description` contains `renovate:` metadata.
- [x] 6.5 Annotate `HUGO_VERSION` and `AUTOPREFIXER_VERSION` Bake variables with Renovate metadata in their standard `description` fields.
- [x] 6.6 Label Docker Bake dependency updates with `image-dependencies` for classification while keeping independent image updates ungrouped so automerge triggers the normal verify and publish path.
- [x] 6.7 Audit every committed operational version pin and document any intentionally unmanaged pin; exclude explanatory OpenSpec example values from dependency updates.

## 7. Verification

- [x] 7.1 Run Docker module tests for the updated Bake support.
- [x] 7.2 Run Dagger scenario tests for the updated container-images scenario.
- [x] 7.3 Run local dry-run verification for `hugo-autoprefixer`.
- [x] 7.4 Run local publish dry-run or equivalent validation for `hugo-autoprefixer`.
- [x] 7.5 Validate the OpenSpec change status is apply-ready.
- [x] 7.6 Update GitHub Actions workflows to call the root Makefile image entry points so local and CI execution use the same commands.
