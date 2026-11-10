# Verify and Dry-run Publish an Image

Use the root Makefile to run the same repository-level image operations locally
that CI workflows should call.

Verify one image:

```bash
make verify docker/hugo-autoprefixer
```

Build the image and validate publication wiring without pushing:

```bash
make publish-dry-run docker/hugo-autoprefixer
```

Publish the image and push its Git release tag:

```bash
GITHUB_TOKEN="$(gh auth token)" \
  make publish docker/hugo-autoprefixer REGISTRY_USERNAME=<username>
```

`GITHUB_TOKEN` authenticates both GHCR publication and Git release tag push.
`REGISTRY_USERNAME` is the GitHub username used for GHCR authentication.

The release tag is built from the image tag, for example
`docker/hugo-autoprefixer/<image-tag>`. When this Git tag already exists on
the remote, `make publish` skips both the image push and the tag push, so a
published image tag is never overwritten. To publish a changed image, change
a value that is part of its image tag.

Both commands require a component directory containing `docker-bake.json`.
Override `CONTAINER_IMAGES_SCENARIO` only when testing an unreleased scenario
version.
