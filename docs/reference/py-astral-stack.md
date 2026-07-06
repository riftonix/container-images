# py-astral-stack

OCI image bundling the Astral toolchain on top of the official `astral/uv`
Python image. It installs `ruff` and `ty` as uv tools so the resulting image
exposes `uv`, `ruff`, `ty`, and `python` on `PATH`.

- Location: `docker/py-astral-stack/`
- Base image: `astral/uv:${UV_VERSION}-python${PYTHON_VERSION}-alpine`
- Publish tag: `${REGISTRY}/${REPOSITORY_PREFIX}/py-astral-stack:py${PYTHON_VERSION}-uv${UV_VERSION}-ruff${RUFF_VERSION}-ty${TY_VERSION}`

With the default values the resolved tag is
`py3.14-uv0.11.25-ruff0.15.20-ty0.0.56`.

## Build arguments

| Argument | Bake variable | Default | Purpose |
| --- | --- | --- | --- |
| `UV_VERSION` | `UV_VERSION` | `0.11.25` | `astral/uv` base image release |
| `PYTHON_VERSION` | `PYTHON_VERSION` | `3.14` | Python minor version embedded in the base image tag |
| `RUFF_VERSION` | `RUFF_VERSION` | `0.15.20` | `ruff` version installed through `uv tool install` |
| `TY_VERSION` | `TY_VERSION` | `0.0.56` | `ty` version installed through `uv tool install` |

`ruff` and `ty` are installed into `/usr/local/bin` (via `UV_TOOL_BIN_DIR`) so
they are immediately available without activating a uv tools directory.

## Renovate metadata

All four Bake variables carry Renovate annotations so the existing regex
manager updates them automatically.

| Variable | datasource | depName | extractVersion |
| --- | --- | --- | --- |
| `UV_VERSION` | `docker` | `astral/uv` | `^(?<version>[0-9]+\.[0-9]+\.[0-9]+)$` |
| `PYTHON_VERSION` | `docker` | `astral/uv` | `^[0-9]+\.[0-9]+\.[0-9]+-python(?P<version>[0-9]+\.[0-9]+)-alpine$` |
| `RUFF_VERSION` | `pypi` | `ruff` | - |
| `TY_VERSION` | `pypi` | `ty` | - |

`UV_VERSION` and `PYTHON_VERSION` both read from the `astral/uv` Docker tag
list but extract different parts of the tag: `UV_VERSION` captures the leading
`X.Y.Z`, while `PYTHON_VERSION` captures the `X.Y` Python segment embedded in
tags such as `0.11.25-python3.14-alpine`. This keeps the Python version pinned
to a tag that the base image actually publishes.

See [Dependency updates](dependency-updates.md) for the annotation format and
the shared regex manager that reads these descriptions.