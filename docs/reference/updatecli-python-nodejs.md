# updatecli-python-nodejs

OCI image bundling Updatecli with Python, PyYAML, Node.js, npm, and git. It
runs Updatecli pipelines whose shell sources and targets need Python scripts,
`npx`-based generators, or git operations, such as the daggerverse
`skills-sync` scenario.

- Location: `docker/updatecli-python-nodejs/`
- Base image: `docker.io/nikolaik/python-nodejs:python3.14-nodejs26`, pinned by
  digest in the `Dockerfile`
- Updatecli source: `/usr/local/bin/updatecli` copied from
  `ghcr.io/updatecli/updatecli:v${UPDATECLI_VERSION}`
- Publish tag: `${REGISTRY}/${REPOSITORY_PREFIX}/updatecli-python-nodejs:py${PYTHON_VERSION}-node${NODE_VERSION}-updatecli${UPDATECLI_VERSION}-pyyaml${PYYAML_VERSION}`
- Runtime user: `pn` (uid `1000`, gid `1000`), working directory `/home/pn`

With the default values the resolved tag is
`py3.14-node26-updatecli0.123.0-pyyaml6.0.3`.

## Contents

| Tool | Source |
| --- | --- |
| `python` 3.14, `pip`, `uv`, `pipenv`, `poetry` | Base image |
| `node` 26, `npm`, `npx`, `yarn` | Base image |
| `git` and Debian build tooling | Base image (`buildpack-deps`) |
| `updatecli` | Official Updatecli image |
| `PyYAML` | Installed with `pip` into the system Python |

The build fails when the base image Python minor version or Node.js major
version differs from `PYTHON_VERSION` or `NODE_VERSION`, or when `updatecli`,
`git`, `npx`, or `import yaml` does not work.

## Build arguments

| Argument | Bake variable | Default | Purpose |
| --- | --- | --- | --- |
| `PYTHON_VERSION` | `PYTHON_VERSION` | `3.14` | Python minor version of the base image, used in the tag and checked at build time |
| `NODE_VERSION` | `NODE_VERSION` | `26` | Node.js major version of the base image, used in the tag and checked at build time |
| `UPDATECLI_VERSION` | `UPDATECLI_VERSION` | `0.123.0` | Updatecli release copied from the official image |
| `PYYAML_VERSION` | `PYYAML_VERSION` | `6.0.3` | PyYAML version installed with `pip` |

## Renovate metadata

| Pin | Location | Manager | Source |
| --- | --- | --- | --- |
| Base image digest | `Dockerfile` `FROM` | Built-in `dockerfile` manager | Digest of `nikolaik/python-nodejs:python3.14-nodejs26` |
| `UPDATECLI_VERSION` | `docker-bake.json` | Bake regex manager | `docker` datasource, `ghcr.io/updatecli/updatecli`, `extractVersion=^v(?<version>[0-9.]+)$` |
| `PYYAML_VERSION` | `docker-bake.json` | Bake regex manager | `pypi` datasource, `PyYAML` |

The base tag `python3.14-nodejs26` is rebuilt upstream without changing its
name, so Renovate proposes digest updates only. Moving to another Python or
Node.js line is a manual change: update the `FROM` tag and digest together
with `PYTHON_VERSION` and `NODE_VERSION`.

See [Dependency updates](dependency-updates.md) for the annotation format and
the shared regex manager that reads these descriptions.
