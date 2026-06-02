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

Docker Bake dependencies opt in through a standard variable description:

```text
renovate: datasource=<datasource> depName=<dependency> [versioning=<scheme>] [extractVersion=<regex>]
```

Renovate updates the variable `default` value. Docker Bake then propagates that
value into build arguments, labels, and publish tags.

## Intentionally Unmanaged Values

The following committed values are configuration rather than dependency pins:

| Location | Value | Reason |
| --- | --- | --- |
| `docker/**/docker-bake.json` | `REGISTRY` | Runtime publication destination |
| `docker/**/docker-bake.json` | `REPOSITORY_PREFIX` | Runtime repository namespace |
| `docker/**/docker-bake.json` | `platforms` entries | Target architectures, not dependency versions |
| `openspec/**` | Example version strings | Design examples, not operational configuration |

## Classification

Renovate labels updates originating from `docker/**/docker-bake.json` with
`image-dependencies`. Updates for independent images remain ungrouped.
