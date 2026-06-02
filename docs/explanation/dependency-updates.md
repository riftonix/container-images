# Dependency Update Design

Operational dependencies appear in workflows and per-image Bake manifests.
Renovate uses its built-in GitHub Actions manager where possible and adds regex
managers only for repository-specific formats.

Bake variable descriptions carry dependency metadata because the variable
`default` remains the source of truth for the build. This keeps each image
self-contained and allows new image directories to opt in without adding
image-specific Renovate rules.

Image dependency updates receive the `image-dependencies` label for
classification. They are intentionally not grouped across `docker/**`
directories: each image is verified and published independently.
