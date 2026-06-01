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
- [x] 4.2 Add Bake target discovery and verification jobs that call Dagger `verify-bake-target`, pinning the external scenario to `scenarios/container-images/v0.1.0`, and require their success from `CI Passed`.
- [x] 4.3 Use the pinned Git module `modules/git/v1.0.0` from the PR workflow to select changed `docker/*` components for the GitHub verification matrix.
- [ ] 4.4 Update the `container-images` scenario so `bake-target` is optional when a Bake manifest contains exactly one target, then simplify provider workflows to pass only the Bake path.
- [ ] 4.5 Add main-branch publish workflow that calls Dagger `publish-bake-target` with GHCR credentials.
- [ ] 4.6 Add post-publish git tag creation for `docker/hugo-autoprefixer/<version>`.
- [ ] 4.7 Make registry and repository prefix independently configurable via workflow environment or input while defaulting to `ghcr.io` and `riftonix/container-images`.
- [ ] 4.8 Ensure workflows request only required permissions for contents, packages, and pull requests.

## 5. Renovate

- [ ] 5.1 Add Renovate base configuration extending the existing daggerverse automerge policy.
- [ ] 5.2 Add a generic Renovate custom manager for `docker/**/docker-bake.json` variables whose `description` contains `renovate:` metadata.
- [ ] 5.3 Annotate `HUGO_VERSION` and `AUTOPREFIXER_VERSION` Bake variables with Renovate metadata in their standard `description` fields.
- [ ] 5.4 Group or label Hugo image dependency updates so automerge triggers the normal verify and publish path.

## 6. Verification

- [ ] 6.1 Run Docker module tests for the updated Bake support.
- [ ] 6.2 Run Dagger scenario tests for the updated container-images scenario.
- [ ] 6.3 Run local dry-run verification for `hugo-autoprefixer`.
- [ ] 6.4 Run local publish dry-run or equivalent validation for `hugo-autoprefixer`.
- [ ] 6.5 Validate the OpenSpec change status is apply-ready.
