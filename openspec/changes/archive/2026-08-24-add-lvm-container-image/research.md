## Wolfi Feasibility Research

Research performed on 2026-08-24 against the public Wolfi package indexes and Chainguard image registry.

### Base Image

- Chainguard publishes the public image through two official registry references:
  - Docker Hub: `docker.io/chainguard/wolfi-base:latest`
  - Chainguard Registry: `cgr.dev/chainguard/wolfi-base:latest`
- The Chainguard Image Directory and the official Docker Hub repository document both pull references. The source repository identifies `cgr.dev/chainguard/wolfi-base` as the canonical OCI reference, while Docker Hub is an official mirror maintained under the verified `chainguard` namespace.
- Both references currently resolve to the same OCI index and platform manifests. Raw manifest comparison returned identical content.
- The public registry exposes only the floating `latest` application tag. Digest tags are signature and attestation artifacts, not versioned base releases.
- Current multi-platform index digest: `sha256:a31344ab2cb8618db84f535eec56f76f6178b142cb92cb2e48676cc2dcebea72`.
- Current platform manifests:
  - `linux/amd64`: `sha256:52604323e2a19f5e6d37dffa7e6a7ef30e2f98506a73a11cdfa3ef25100131be`
  - `linux/arm64`: `sha256:aa58277d1dc347a73505212255a6e51729d6cc4d1500321e011893edb9ee42d8`
- The Wolfi `wolfi-base` metapackage is version `1-r7` and intentionally static. It installs `apk-tools`, `busybox`, and `wolfi-keys`. This metapackage version does not identify changing image contents.
- Use Docker Hub for this image component: `docker.io/chainguard/wolfi-base:latest@sha256:<index-digest>`. Docker Hub is the conventional public registry, works without a separate registry host configuration, and preserves the same signed multi-platform content as `cgr.dev`.
- Keep `cgr.dev/chainguard/wolfi-base:latest@sha256:<index-digest>` as the fallback source if Docker Hub rate limiting becomes a practical CI issue.
- Pin the multi-platform index digest rather than either architecture manifest so one Dockerfile reference supports both `linux/amd64` and `linux/arm64` reproducibly.
- Renovate can update the base digest with `datasource=docker depName=chainguard/wolfi-base versioning=docker` while retaining `latest` as the tag.

### LVM2 Package

- Current Wolfi recipe upstream version: `2.03.42` with package epoch `1`.
- Current package index version: `2.03.42-r1` for both `x86_64` and `aarch64`.
- Package revision format is `<upstream-version>-r<revision>`. The apk revision reflects Wolfi recipe rebuilds; the recipe epoch is not rendered in the apk version.
- Wolfi retains older package builds in its append-only package index. Exact installation must therefore use `lvm2=2.03.42-r1`, not an unversioned `apk add lvm2`.
- The exact Wolfi package version `2.03.42-r1` is the single LVM Bake version input. It pins `apk add`, OCI version metadata, and the public image tag.
- The public image tag is therefore `2.03.42-r1`. The Wolfi base digest and default `sleep infinity` behavior do not contribute to it.
- Repology does not expose a confirmed Wolfi repository identifier, so it is not a reliable datasource for the exact apk revision.
- Renovate-compatible sources:
  - upstream version: `datasource=github-tags depName=lvmteam/lvm2 extractVersion=^v(?<version>[0-9_]+)$` would still require underscore-to-dot normalization, which Renovate extraction does not provide cleanly;
  - practical upstream tracking: use `datasource=custom` backed by the Wolfi `lvm2.yaml`, or add a repository regex/custom datasource that reads `package.version` and `package.epoch`;
  - exact package revision: use a custom datasource backed by `https://packages.wolfi.dev/os/x86_64/APKINDEX.tar.gz`, or keep it as an explicitly documented manual pin until such a datasource is added.
- The existing generic Bake annotation parser supports datasource names but does not itself define a custom Wolfi datasource. Task 2.2 will need either a Renovate custom datasource or a documented exception; `repology` should not be assumed to work.

### Package Contents

The inspected `lvm2-2.03.42-r1.apk` files are equivalent across `x86_64` and `aarch64`, apart from architecture-specific binaries and SBOM data.

- Required commands are present under `/usr/bin`:
  - `/usr/bin/lvm` is the dynamic multicall executable.
  - `/usr/bin/pvcreate`, `/usr/bin/vgcreate`, and `/usr/bin/vgs` are symlinks to `lvm`.
  - `/usr/bin/lvm.static` is also included and has no dynamic ELF dependencies.
- The package also includes the full standard PV, VG, and LV command set, plus `lvmconfig`, `lvmdevices`, `lvmdiskscan`, and static `dmsetup` helpers.
- Default configuration is included:
  - `/etc/lvm/lvm.conf`
  - `/etc/lvm/lvmlocal.conf`
  - profiles under `/etc/lvm/profile/`
- LVM event plugins are included under `/usr/lib/device-mapper/`.
- Udev rules are included under `/usr/lib/udev/rules.d/`, but the package does not require a running udev daemon.
- Systemd unit files are included but are not needed merely to invoke the target LVM commands.

### Runtime Dependency Closure

The apk metadata for the dynamic LVM executable requires:

- `bash`, because packaged helper scripts use it;
- Wolfi layout compatibility packages: `merged-lib`, `merged-sbin`, `merged-usrsbin`, and `wolfi-baselayout`;
- glibc and the architecture loader;
- `libaio.so.1`;
- `libblkid.so.1`;
- `libdevmapper.so.1.02`;
- `libdevmapper-event.so.1.02`;
- `libm.so.6` on `x86_64`, with the architecture index resolving the equivalent closure on `aarch64`.

Direct ELF inspection of `/usr/bin/lvm` and `/usr/lib/liblvm2cmd.so.2.03` confirms the same dynamic libraries. Apk resolves them transitively from the package index, so they should not be listed separately in the Dockerfile.

The `device-mapper` command subpackage depends on `lvm2` and provides dynamic `dmsetup`, `dmstats`, and `dmeventd`. It is not required for `pvcreate`, `vgcreate`, and `vgs`, because `lvm2` already contains the LVM multicall binary, device-mapper libraries, event plugins, and static device-mapper helpers. Add `device-mapper` only if later privileged validation proves the dynamic commands are required.

`util-linux` is a build dependency through `util-linux-dev`, not an explicit runtime package. Its `libblkid` runtime library is pulled through the ELF dependency provider. `udev`, `systemd`, `coreutils`, and thin-provisioning tools are not declared runtime requirements for the target commands and should not be added before functional validation.

### Infinite Sleep

- The inspected `wolfi-base` image provides `/usr/bin/sleep` through the BusyBox multicall binary. The tested base contains BusyBox `1.38.0`.
- `docker run cgr.dev/chainguard/wolfi-base:latest sleep infinity` remained in the running state on `linux/amd64` until explicitly stopped.
- A separate timeout check also confirmed that the command did not exit during the observation period.
- The `linux/arm64` manifest contains the same Wolfi base package set, including BusyBox. The local amd64 Docker host could pull the arm64 manifest but could not execute it because aarch64 binfmt emulation is not installed (`exec format error`). This is a host execution limitation, not a missing image command.
- No additional runtime package is needed for the default command. In particular, `coreutils` must not be added solely for `sleep infinity`.
- The Dockerfile can use exec form directly: `CMD ["sleep", "infinity"]`.

### Sources

- Wolfi package indexes: `https://packages.wolfi.dev/os/{x86_64,aarch64}/APKINDEX.tar.gz`
- Wolfi LVM2 recipe: `https://github.com/wolfi-dev/os/blob/main/lvm2.yaml`
- Wolfi base recipe: `https://github.com/wolfi-dev/os/blob/main/wolfi-base.yaml`
- Chainguard Image Directory: `https://images.chainguard.dev/directory/image/wolfi-base/overview`
- Docker Hub mirror: `https://hub.docker.com/r/chainguard/wolfi-base`
- Selected base reference: `docker.io/chainguard/wolfi-base:latest@sha256:a31344ab2cb8618db84f535eec56f76f6178b142cb92cb2e48676cc2dcebea72`
- Registry fallback: `cgr.dev/chainguard/wolfi-base:latest@sha256:a31344ab2cb8618db84f535eec56f76f6178b142cb92cb2e48676cc2dcebea72`
- Inspected packages: `https://packages.wolfi.dev/os/{x86_64,aarch64}/lvm2-2.03.42-r1.apk`

### Pipeline Integration Results

- Changed-component discovery against a temporary committed fixture returned `docker/lvm` for the new Dockerfile and Bake manifest.
- Metadata-only release marker rendering returned `docker/lvm/2.03.42-r1`.
- `make verify docker/lvm` successfully built the Bake target for both `linux/amd64` and `linux/arm64`.
- `make publish-dry-run docker/lvm` resolved `ghcr.io/riftonix/container-images/lvm:2.03.42-r1` and completed without pushing.
- No image-specific verification integration was added to the generic pipeline; privileged and runtime-specific validation remains in section 3.

### Runtime Validation Results

- Required commands `lvm`, `pvcreate`, `vgcreate`, and `vgs` are present, and `/etc/lvm/lvm.conf` is readable.
- The installed package is exactly `lvm2-2.03.42-r1`; `lvm version` reports LVM `2.03.42`, library `1.02.216`, and device-mapper driver `4.50.0` in the privileged test environment.
- The default `CMD ["sleep", "infinity"]` keeps the container running until explicitly stopped.
- An isolated privileged test created a temporary physical volume and volume group on a disposable loop device, confirmed the group with `vgs`, and removed both the group and physical-volume label successfully.
- LVM device discovery was constrained to the disposable loop device during the test, and temporary resources were cleaned up.
- The intended Kubernetes runtime requires privileged access and the existing `/dev` bind mount. `/dev/mapper/control` is available through that mount.
- No separate `/run/udev` or `/run/lvm` mount was required for `pvcreate`, `vgcreate`, `vgs`, `vgremove`, or `pvremove`.
- No additional `device-mapper`, `util-linux`, `udev`, or coreutils package is required in the LVM image. A separate helper supplied `losetup` only to create the disposable test device.
- Dagger built and executed smoke checks for both `linux/amd64` and `linux/arm64`; both variants contain the exact LVM2 package, required commands, and configuration. The privileged device-mapper lifecycle was run on the amd64 host kernel.
