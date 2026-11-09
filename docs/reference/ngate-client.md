# ngate-client

OCI image that connects a Linux host to a CryptoPro NGate VPN gateway through
the vendor console client `ngateconsoleclient`. The NGate client is part of
the image. CryptoPro CSP is distributed only through an authenticated
repository, so the entrypoint installs it on the first container start. On
every start the entrypoint then applies the CSP license, installs trusted root
certificates, starts the NGate TUN helper, and logs in to the gateway.

- Location: `docker/ngate-client/`
- Base image: `docker.io/library/ubuntu:24.04@<digest>`
- Publish tag: `${REGISTRY}/${REPOSITORY_PREFIX}/ngate-client:${NGATE_VERSION}-csp${CSP_VERSION}`
- Entrypoint: `tini -- ngate-client-entrypoint`
- Platforms: `linux/amd64`

For example, `NGATE_VERSION=1.0.30-213-g9526b28` and `CSP_VERSION=5.0.13000-7`
produce an image tag ending in `:1.0.30-213-g9526b28-csp5.0.13000-7`. The tag
names the NGate version inside the image and the CSP version it installs.

## Build Arguments

| Argument | Bake variable | Purpose |
| --- | --- | --- |
| `CSP_VERSION` | `CSP_VERSION` | CryptoPro CSP package version installed at container start |
| `NGATE_VERSION` | `NGATE_VERSION` | `cprongate-tun` and `cprongate-console` package version extracted at build time |
| `NGATE_TUN_SHA256` | `NGATE_TUN_SHA256` | Expected SHA256 of the `cprongate-tun` amd64 package |
| `NGATE_CONSOLE_SHA256` | `NGATE_CONSOLE_SHA256` | Expected SHA256 of the `cprongate-console` amd64 package |

`CSP_VERSION` also becomes an environment variable of the same name, so a
container can install another CSP build by overriding it at runtime.

The image adds `expect`, `tini`, `network-manager` (for `nmcli`), `iproute2`,
`curl`, `ca-certificates`, `lsb-base`, and the `libglib2.0-0t64` and
`libdbus-1-3` libraries the NGate binaries link against. NGate configures routes and
DNS through `nmcli` and the host NetworkManager; `ip` is its fallback path.
Package service startup is disabled, and no D-Bus or NetworkManager runs
inside the container. The build fails if `ldd` reports a missing library for
either NGate binary.

## Vendor Packages

| Package | Installed | Provides |
| --- | --- | --- |
| `cprongate-tun` | At build time | `ngatetun` TUN helper |
| `cprongate-console` | At build time | `ngateconsoleclient` |
| `lsb-cprocsp-base` | On first start | CSP directories and scripts |
| `lsb-cprocsp-rdr-64` | On first start | `cpconfig`, `libcapi10.so`, `librdrsup.so` |
| `lsb-cprocsp-kc1-64` | On first start | KC1 cryptographic provider |
| `lsb-cprocsp-capilite-64` | On first start | `certmgr`, `libcapi20.so`, `libssp.so` |

The NGate packages come from the public, unsigned repository
`https://ng-client.cryptopro.ru/repository/debian/amd64_snapshot`. The build
checks them against the pinned SHA256 values and extracts only
`/opt/cprongate`; they are not registered in the dpkg database. The repository
keeps only the latest release, so after a vendor update the image no longer
builds until `NGATE_VERSION` and both checksums are updated. Published images
are not affected.

The CSP repository defaults to `https://cryptopro.ru/repo/deb`, suite
`5.0-unstable`. It requires a cryptopro.ru account and is signed with the
CryptoPro key stored in the image as `/usr/share/keyrings/cryptopro.asc`
(fingerprint `6A98 57CD 9DAE F5DC CF96 922C E033 4293 0A70 9346`). CryptoPro
positions this repository for testing.

CSP is installed when `lsb-cprocsp-capilite-64` of version `CSP_VERSION` is not
yet configured, so a restarted container skips installation and a recreated
container installs again. The repository credentials are written to
`/etc/apt/auth.conf.d/` with mode `0600` only for the duration of the
installation and are removed together with the downloaded packages.

The entrypoint runs CSP tools, including the calls in the capilite `postinst`
script, through the ELF loader `/lib64/ld-linux-x86-64.so.2`. This keeps host
AppArmor profiles attached to the CSP executable paths from applying inside
the container. Vendor binaries are not modified.

## Runtime Configuration

| Variable | Required | Purpose |
| --- | --- | --- |
| `CRYPTOPRO_USERNAME`, `CRYPTOPRO_PASSWORD` | On installation | cryptopro.ru account for the CSP repository |
| `CSP_LICENSE` | No | CSP license serial number applied on every start |
| `CSP_REPO_URL`, `CSP_REPO_SUITE` | No | Override the CSP repository location and suite |
| `NGATE_URL` | Yes | Gateway URL, for example `https://ng-av.crpt.ru` |
| `NGATE_USERNAME`, `NGATE_PASSWORD` | Yes | Gateway login and password |
| `NGATE_OTP` | When the gateway asks for it | Answer to the gateway OTP prompt, such as the confirmation method number |

Values passed with `-e` are visible in `docker inspect`.

Without `CSP_LICENSE` the CSP runs on its trial license, which expires 90 days
after installation. The entrypoint prints only the license kind and validity,
never the serial number.

Every file in `/etc/ngate-client/ca.d` is installed into the CSP machine root
store (`mroot`) on every start. The gateway certificate must chain to one of
these roots. On a host where the desktop client already works, a root can be
exported by its SHA1 thumbprint:

```bash
/opt/cprocsp/bin/amd64/certmgr -list -store mroot
/opt/cprocsp/bin/amd64/certmgr -export -store mroot -thumbprint <sha1> -dest root.cer
```

Container arguments are passed to `ngateconsoleclient` before the gateway
URL, for example `-v` for more verbose logs or `--disable-proxy`.

## Login Flow

The entrypoint runs `ngateconsoleclient -K -v <arguments> <NGATE_URL>` under
`expect`, which answers the client prompts:

1. The username and password prompts receive `NGATE_USERNAME` and
   `NGATE_PASSWORD`. Pty echo is disabled, so the values do not appear in the
   container log.
2. When the gateway asks for an OTP, the prompt receives `NGATE_OTP`. If the
   account has several confirmation methods, the gateway asks for the method
   number. With a single method it sends the push without a prompt, and
   `NGATE_OTP` can be omitted. The login completes after the push is approved
   on the device.
3. After `VPN session online` the attempt counters reset. The password and
   OTP prompts are each answered at most three times in a row before the
   container exits.

The `-K` flag starts a new session when the gateway session expires, which
repeats the login and the OTP confirmation. The container exits with an error
when the gateway requests an OTP without `NGATE_OTP` set, a password change,
an OTP PIN, or certificate authentication.

When the client exits, the container exits with the client status. A restart
policy such as `--restart unless-stopped` reconnects automatically, and each
reconnect requests a new OTP confirmation.

## Running the Container

Use rootful Docker without user namespace remapping, with NetworkManager
running on the Linux host. The container needs `CAP_NET_ADMIN`,
`/dev/net/tun`, host networking, and the host system D-Bus socket mounted at
`/run/dbus/system_bus_socket`.

```bash
docker run -d --name ngate-client \
  --restart unless-stopped \
  --network host \
  --cap-add NET_ADMIN \
  --device /dev/net/tun \
  --security-opt apparmor=unconfined \
  --mount type=bind,src=/run/dbus/system_bus_socket,dst=/run/dbus/system_bus_socket,readonly \
  -v "$PWD/ca:/etc/ngate-client/ca.d:ro" \
  -e CRYPTOPRO_USERNAME=<login> \
  -e CRYPTOPRO_PASSWORD=<password> \
  -e CSP_LICENSE=<serial> \
  -e NGATE_URL=https://ng-av.crpt.ru \
  -e NGATE_USERNAME=<login> \
  -e NGATE_PASSWORD=<password> \
  ghcr.io/riftonix/container-images/ngate-client:<version>
```

If the gateway asks to choose a confirmation method, add
`-e NGATE_OTP=<number>`.

With host networking the `tun0` interface and gateway routes appear in the
host network namespace, and NGate applies network and DNS settings through
the host NetworkManager.

On AppArmor-enabled hosts, `apparmor=unconfined` is required because the
default container profile blocks access to the host system bus. The mounted
socket grants access to the whole host system bus, and the `readonly` mount
option does not prevent mutating D-Bus requests, so only use a trusted image.
Do not run another NGate connection on the host at the same time.

To run the container from a prepared file instead, see
[Run ngate-client with Docker Compose](../how-to/run-ngate-client-with-docker-compose.md).

After approving MFA, check the connection from the host:

```bash
nmcli device show tun0
getent hosts known-host.crpt.local
```

## Renovate Metadata

The base image digest in the `Dockerfile` `FROM` line is managed by the
built-in `dockerfile` manager. The vendor package variables have no Renovate
annotations; see [Dependency updates](dependency-updates.md#intentionally-unmanaged-values).

The image tag in `docs/how-to/ngate-client/docker-compose.yaml` is managed by the
built-in `docker-compose` manager against the published `ghcr.io` image. A
package rule orders the tags with `regex` versioning: first by the NGate
version and its build number, then by the CSP build number.
