# Dependency Updates

Renovate manages committed operational dependency pins. Version strings used
only as examples under `openspec/**` are intentionally outside the dependency
update scope.

## Managed Pins

| Location | Dependency category | Renovate manager |
| --- | --- | --- |
| `.github/workflows/*.yaml` `uses:` references | GitHub Actions | Built-in `github-actions` manager |
| `.github/workflows/*.yaml` `DAGGER_VERSION` | Dagger CLI | Regex manager backed by the Manjaro stable extra mirror |
| `Makefile` daggerverse refs | Released Dagger modules and scenarios | Regex manager backed by GitHub tags |
| `docker/**/docker-bake.json` annotated variables | Image-specific dependencies | Regex manager using `description` metadata |
| `docker/**/Dockerfile` literal `FROM` references with a digest | Base image digests | Built-in `dockerfile` manager |
| `docs/how-to/**/docker-compose.yaml` `image:` references | Published images of this repository | Built-in `docker-compose` manager |

Docker Bake dependencies opt in through a standard variable description:

```text
renovate: datasource=<datasource> depName=<dependency> [versioning=<scheme>] [extractVersion=<regex>]
```

Renovate updates the variable `default` value. Docker Bake then propagates that
value into build arguments, labels, and publish tags.

The `lvm` image uses two annotated variables:

| Variable | Managed value | Tag behavior |
| --- | --- | --- |
| `WOLFI_BASE_DIGEST` | Wolfi multi-platform base digest | Does not affect the image tag |
| `LVM_PACKAGE_VERSION` | Exact Wolfi `lvm2` package version | Used as the complete image tag |

The Wolfi package variable uses the repository's `custom.wolfi` datasource and
`loose` versioning so package revisions such as `-r1` remain part of the
managed version.

The `ngate-client` tag `<ngate-version>-<build>-g<commit>-csp<csp-version>`
does not fit `docker` versioning, which treats everything after the first `-`
as a compatibility suffix. A package rule in `renovate.json` switches it to
`regex` versioning and compares the NGate version, the NGate build number, and
the CSP build number.

## Intentionally Unmanaged Values

The following committed values are configuration rather than dependency pins:

| Location | Value | Reason |
| --- | --- | --- |
| `docker/**/docker-bake.json` | `REGISTRY` | Runtime publication destination |
| `docker/**/docker-bake.json` | `REPOSITORY_PREFIX` | Runtime repository namespace |
| `docker/**/docker-bake.json` | `platforms` entries | Target architectures, not dependency versions |
| `docker/updatecli-python-nodejs/docker-bake.json` | `PYTHON_VERSION`, `NODE_VERSION` | Base image line selection, kept in sync with the `Dockerfile` `FROM` tag and checked at build time |
| `docker/ngate-client/docker-bake.json` | `CSP_VERSION`, `NGATE_VERSION`, `NGATE_TUN_SHA256`, `NGATE_CONSOLE_SHA256` | Vendor packages come from an authenticated repository and a flat repository without release metadata, which Renovate cannot query; update the version and both checksums together by hand |
| `openspec/**` | Example version strings | Design examples, not operational configuration |

## Classification

Renovate labels updates originating from `docker/**/docker-bake.json` and
`docker/**/Dockerfile` with `image-dependencies`. Updates for independent images remain ungrouped.
