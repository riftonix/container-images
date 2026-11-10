# ngate-client

OCI image that connects to a CryptoPro NGate VPN gateway through the vendor
console client `ngateconsoleclient`. It either brings the tunnel up on a Linux
host with NetworkManager or acts as a gateway that other hosts route traffic
through. The NGate client is part of the image. CryptoPro CSP is distributed only through an authenticated
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
`iptables`, `curl`, `ca-certificates`, `lsb-base`, and the `libglib2.0-0t64`
and `libdbus-1-3` libraries the NGate binaries link against. It also ships a
`resolvconf` script that receives the tunnel DNS settings in gateway mode; see
[Network Modes](#network-modes). `LANG` is set to `C.UTF-8` for the Qt runtime
of the NGate binaries. Package service startup is disabled, and no D-Bus or
NetworkManager runs inside the container. The build fails if `ldd` reports a
missing library for either NGate binary.

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
script, through the ELF loader `/lib64/ld-linux-x86-64.so.2`. In
`networkmanager` mode the container runs with `apparmor=unconfined`, and this
keeps host AppArmor profiles attached to the CSP executable paths from
applying inside the container. Vendor binaries are not modified.

## Runtime Configuration

| Variable | Required | Purpose |
| --- | --- | --- |
| `CRYPTOPRO_USERNAME`, `CRYPTOPRO_PASSWORD` | On installation | cryptopro.ru account for the CSP repository |
| `CSP_LICENSE` | No | CSP license serial number applied on every start |
| `CSP_REPO_URL`, `CSP_REPO_SUITE` | No | Override the CSP repository location and suite |
| `NGATE_URL` | Yes | Gateway URL, for example `https://ng-av.crpt.ru` |
| `NGATE_USERNAME`, `NGATE_PASSWORD` | Yes | Gateway login and password |
| `NGATE_OTP` | When the gateway asks for it | Answer to the gateway OTP prompt, such as the confirmation method number |
| `NGATE_MODE` | No | `networkmanager` (default) or `gateway`; see [Network Modes](#network-modes) |

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

NGate writes its own logs to `/opt/cprongate/ngate_tun_service.log` and
`/opt/cprongate/ngate_console_client.log` inside the container. The TUN helper
log shows which integration NGate uses, for example
`NetworkManager support enabled` or `NetworkManager support disabled by request`.

## Network Modes

`NGATE_MODE` selects how the tunnel reaches the network:

| Mode | Container network | Routes | DNS | Host requirements |
| --- | --- | --- | --- | --- |
| `networkmanager` | Host | NGate through the host NetworkManager | NGate through the host NetworkManager | NetworkManager, D-Bus socket, `apparmor=unconfined` |
| `gateway` | Own | NGate with `ip` inside the container | Passed to `resolvconf` and recorded only | `net.ipv4.ip_forward=1`, routes to the container |

In `networkmanager` mode the entrypoint checks the D-Bus socket and
NetworkManager before installing CSP. `tun0`, the gateway routes, and the DNS
servers and domains appear on the host and are removed when the container
stops.

In `gateway` mode the entrypoint writes `ignoreNetworkManager=1` to
`/opt/cprongate/service.ini`, so NGate configures `tun0` and the gateway
routes inside the container with `ip`. Before CSP is installed, the entrypoint
enables IP forwarding and adds `iptables` rules:

- `MASQUERADE` for traffic leaving through `tun0`, so the gateway sees the
  tunnel address;
- TCP MSS clamping for traffic entering `tun0`;
- forwarding only into `tun0` and for established connections; other
  forwarded traffic is rejected, so addresses the gateway does not route do
  not loop back to the host that sent them.

The rules use the nf_tables backend when the kernel supports it and
`iptables-legacy` otherwise. Docker does not let a container change
`ip_forward`, so pass `--sysctl net.ipv4.ip_forward=1`.

NGate passes the tunnel DNS settings to `resolvconf -a tun0.ngate` and removes
them with `resolvconf -d tun0.ngate`. The image script logs the settings and
keeps them in `/run/ngate-client/dns` while the tunnel is up, for example:

```text
nameserver 10.77.103.241
nameserver 10.77.103.242
domain crpt.local
search crpt.local . crpt.tech crpt.ru crptech.ru crpt.cloud crpt.intranet ittds.tech trekmark.ru crpt.team ~
```

The routing hosts must send the gateway networks to the container address and
forward the gateway domains to these DNS servers themselves.

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

### NetworkManager Mode

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
resolvectl status tun0
resolvectl query crpt.local
```

On hosts where `nsswitch.conf` sends `.local` names to mDNS
(`mdns4_minimal [NOTFOUND=return]`), `getent` and applications do not resolve
names under `crpt.local` even though `resolvectl query` does.

### Gateway Mode

The container needs `CAP_NET_ADMIN`, `/dev/net/tun`, its own network with a
fixed address, and IP forwarding. It does not need D-Bus or
`apparmor=unconfined`:

```bash
docker network create --subnet 172.30.0.0/24 ngate
docker run -d --name ngate-gateway \
  --network ngate --ip 172.30.0.2 \
  --cap-add NET_ADMIN \
  --device /dev/net/tun \
  --sysctl net.ipv4.ip_forward=1 \
  -v "$PWD/ca:/etc/ngate-client/ca.d:ro" \
  -e NGATE_MODE=gateway \
  -e CRYPTOPRO_USERNAME=<login> \
  -e CRYPTOPRO_PASSWORD=<password> \
  -e NGATE_URL=https://ng-av.crpt.ru \
  -e NGATE_USERNAME=<login> \
  -e NGATE_PASSWORD=<password> \
  ghcr.io/riftonix/container-images/ngate-client:<version>
```

Hosts that use the tunnel route the gateway networks to `172.30.0.2`. The
routes applied by NGate are visible inside the container:

```bash
docker exec ngate-gateway ip route show dev tun0
docker exec ngate-gateway cat /run/ngate-client/dns
```

## Renovate Metadata

The base image digest in the `Dockerfile` `FROM` line is managed by the
built-in `dockerfile` manager. The vendor package variables have no Renovate
annotations; see [Dependency updates](dependency-updates.md#intentionally-unmanaged-values).

The image tag in `docs/how-to/ngate-client/docker-compose.yaml` is managed by the
built-in `docker-compose` manager against the published `ghcr.io` image. A
package rule orders the tags with `regex` versioning: first by the NGate
version and its build number, then by the CSP build number.
