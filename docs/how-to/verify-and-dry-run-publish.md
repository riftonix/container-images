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

Both commands require a component directory containing `docker-bake.json`.
Override `CONTAINER_IMAGES_SCENARIO` only when testing an unreleased scenario
version.
