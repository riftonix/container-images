# opencode

Agent image derived directly from the official OpenCode v2 image. It includes
the everyday tools needed to edit and check this organization's repositories,
plus Node.js, npm/npx and kubectl. Project-specific SDKs and utilities can be
installed into a writable volume without running the agent as root.

- Location: `docker/opencode/`
- Base image: `ghcr.io/anomalyco/opencode:${OPENCODE_VERSION}`, referenced by
  tag only
- Publish tag: `${REGISTRY}/${REPOSITORY_PREFIX}/opencode:${OPENCODE_VERSION}`
- Platforms: `linux/amd64`, `linux/arm64`
- User: `agent`, UID/GID `65532:65532`
- Working directory: `/workspace`
- Entrypoint: `/sbin/tini -g -- opencode`

## Included tools

The image contains Bash, GNU coreutils, findutils, grep, sed, awk, Git, an SSH
client, curl, ripgrep, jq, tar, gzip, unzip, xz, make, diff, patch, Python with
venv support, uv/uvx, Ruff, procps, Node.js, npm/npx and kubectl. It does not
include an SSH server, container daemon, Go SDK, Helm, OpenTofu or Dagger.

The official base uses Alpine and musl, not glibc. Additional native
executables and Python wheels must support musl and the Pod's architecture;
do not assume arbitrary glibc binaries will run.

## Versions and updates

`OPENCODE_VERSION` in `docker-bake.json` is the only version input. It selects
the official base image and this image's release tag, and Renovate updates it
through the `docker` datasource. The Dockerfile has no fallback for it, so
build through Bake. The base is referenced by tag without a digest; the build
fails if the base's `opencode --version` does not match `OPENCODE_VERSION`.

APK packages are not pinned. The build runs `apk upgrade` and then installs the
tools, so every package resolves to the newest revision in the Alpine branch of
the official base at build time. The upstream image selects the Alpine branch,
which therefore determines the package versions, including the Node.js, Python
and kubectl major and minor versions. Two builds of the same commit can contain
different package revisions.

Renovate merges OpenCode minor and patch updates automatically after CI passes.
Major updates of any dependency in the repository are proposed but not merged
automatically. When an OpenCode update moves the base to a new Alpine branch,
check the resulting package versions, especially kubectl compatibility with
the target clusters.

Dependency updates do not change the release tag. Under the existing
publication workflow, they ship with the next OpenCode release rather than
republishing an existing release tag.

## Writable paths in Kubernetes

| Path | Purpose |
| --- | --- |
| `/workspace` | Git checkout and working files |
| `/tools` | Additional executables and npm global packages |
| `/home/agent` | OpenCode configuration/state, uv tools and package caches |
| `/tmp` | Temporary files |

`/tools/bin` is first on `PATH`. `UV_TOOL_BIN_DIR=/tools/bin` and
`NPM_CONFIG_PREFIX=/tools` direct additional tool entrypoints there. XDG paths
are set below `/home/agent`; the image contains no credentials or kubeconfig.

For a read-only root filesystem, mount writable volumes at all four paths.
Use `runAsUser: 65532`, `runAsGroup: 65532` and a Pod-level `fsGroup: 65532` so
mounted volumes are writable. A volume mounted over the home directory hides
the image's precreated XDG directories; OpenCode and package managers create
their directories as needed. Configuration can be mounted separately.

An `emptyDir` survives a container restart but is removed with its Pod. Use
persistent storage for OpenCode state and authentication if they must survive
Pod replacement. Tool downloads require network access and should use explicit
versions and checksum verification. Volumes holding executables or virtual
environments must permit execution, without `noexec`. Docker `--tmpfs` tests
need an explicit `exec` option for those paths. Runtime installation of OS packages is not
supported under the default non-root user.

kubectl is available, but access still requires suitable credentials and RBAC.
Its minor version must be compatible with the target API server. Merely running
this image in a Pod does not grant cluster access.

## Local verification

From the repository root, build and load the host architecture:

```sh
docker buildx bake -f docker/opencode/docker-bake.json opencode \
  --set opencode.platform=linux/amd64 \
  --set opencode.tags=opencode-agent:local --load
docker run --rm opencode-agent:local --version
docker run --rm --entrypoint sh opencode-agent:local \
  /usr/local/share/opencode-image/smoke-test.sh
```

Use `linux/arm64` on an ARM host. The build fails if the copied OpenCode binary
does not report `OPENCODE_VERSION`. The smoke script also runs during the image
build, under UID/GID 65532. It checks that the expected executables are
present, that the GNU and procps-ng tools take precedence over BusyBox, the
version commands, Python venv/SSL/SQLite support, `uv venv`, Git initialization
and commit, and writable directories. `kubectl version --client` does not
contact a cluster. Caches and logs written by the checks go to a temporary
directory that is removed afterwards.

The existing `make verify docker/opencode` entrypoint delegates multi-platform
verification to Dagger. Neither verification command publishes the image.
