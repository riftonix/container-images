# hugo-autoprefixer

OCI image bundling Hugo with the `autoprefixer` PostCSS plugin installed
globally through npm.

- Location: `docker/hugo-autoprefixer/`
- Base image: `hugomods/hugo:debian-${HUGO_VERSION}`
- Publish tag: `${REGISTRY}/${REPOSITORY_PREFIX}/hugo-autoprefixer:${HUGO_VERSION}-${AUTOPREFIXER_VERSION}`

## Build arguments

| Argument | Bake variable | Default | Purpose |
| --- | --- | --- | --- |
| `HUGO_VERSION` | `HUGO_VERSION` | `0.163.3` | Hugo release bundled in the base image |
| `AUTOPREFIXER_VERSION` | `AUTOPREFIXER_VERSION` | `10.5.2` | `autoprefixer` npm package version installed globally |

## Renovate metadata

Both Bake variables carry Renovate annotations so the existing regex manager
updates them automatically.

| Variable | datasource | depName | extractVersion |
| --- | --- | --- | --- |
| `HUGO_VERSION` | `docker` | `hugomods/hugo` | `^debian-(?<version>.+)$` |
| `AUTOPREFIXER_VERSION` | `npm` | `autoprefixer` | - |

See [Dependency updates](dependency-updates.md) for the annotation format and
the shared regex manager that reads these descriptions.