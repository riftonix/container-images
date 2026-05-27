## Why

This repository needs a repeatable monorepo workflow for building and publishing base OCI images while keeping CI provider logic thin. Docker Buildx Bake can provide a standard build manifest, and Dagger should own the actual verify and publish behavior.

## What Changes

- Add per-image `docker-bake.json` files as the source of truth for image build targets, build arguments, labels, platforms, and publish tags.
- Add the first image context at `docker/hugo-autoprefixer`, based on `hugomods/hugo:exts-${HUGO_VERSION}` with `autoprefixer@${AUTOPREFIXER_VERSION}` installed.
- Version the Hugo image as `<hugo-version>-<autoprefixer-version>`, for example `0.147.1-10.4.21`.
- Publish the image as `ghcr.io/riftonix/container-images/hugo-autoprefixer:<tag>`.
- Extend the reusable Dagger Docker module to build from Docker Bake targets using Dagger-native APIs, including image reference accessors on `DockerBuild`.
- Extend the Dagger container-images scenario with thin verify/publish wrappers for Docker Bake targets.
- Add GitHub Actions workflows that trigger verification and publication, but delegate image build/publish logic to Dagger.
- Add Renovate configuration so Hugo and autoprefixer version bumps are automatically proposed and automerged.
- Create git tags after successful publication in the form `docker/hugo-autoprefixer/<tag>`.
- Allow the registry/repository prefix to be overridden while defaulting to `ghcr.io/riftonix/container-images`.

## Capabilities

### New Capabilities

- `container-image-bake-pipeline`: Build, verify, publish, tag, and update monorepo OCI images described by Docker Buildx Bake targets.

### Modified Capabilities

- None.

## Impact

- Adds Docker image source under `docker/hugo-autoprefixer`.
- Adds Docker Buildx Bake metadata in `docker/hugo-autoprefixer/docker-bake.json`.
- Modifies the reusable Dagger Docker module to support Bake target resolution and image references on `DockerBuild`.
- Modifies or vendors the Dagger container-images scenario integration to expose CI-facing Bake verify/publish functions.
- Adds GitHub Actions workflows for PR verification and main-branch publication.
- Adds Renovate custom managers/package rules for Dockerfile or bake-managed version updates.
- Uses GHCR package publishing and repository git tags as release markers.
