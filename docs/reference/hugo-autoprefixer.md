# hugo-autoprefixer

OCI image bundling Hugo with the `autoprefixer` PostCSS plugin installed
globally through npm.

- Location: `docker/hugo-autoprefixer/`
- Base image: `hugomods/hugo:std-dart-sass-node-${HUGO_VERSION}`
- Publish tag: `${REGISTRY}/${REPOSITORY_PREFIX}/hugo-autoprefixer:${HUGO_VERSION}-${AUTOPREFIXER_VERSION}`

## Build arguments

| Argument | Bake variable | Default | Purpose |
| --- | --- | --- | --- |
| `HUGO_VERSION` | `HUGO_VERSION` | `0.165.0` | Hugo release bundled in the base image |
| `AUTOPREFIXER_VERSION` | `AUTOPREFIXER_VERSION` | `10.5.5` | `autoprefixer` npm package version installed globally |

## Renovate metadata

Both Bake variables carry Renovate annotations so the existing regex manager
updates them automatically.

| Variable | datasource | depName | extractVersion |
| --- | --- | --- | --- |
| `HUGO_VERSION` | `docker` | `hugomods/hugo` | `^std-dart-sass-node-(?<version>.+)$` |
| `AUTOPREFIXER_VERSION` | `npm` | `autoprefixer` | - |

See [Dependency updates](dependency-updates.md) for the annotation format and
the shared regex manager that reads these descriptions.