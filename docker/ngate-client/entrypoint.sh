#!/bin/bash
# Installs CryptoPro CSP on the first start, applies the CSP license and the
# trusted root certificates from NGATE_ROOT_CERTIFICATES, starts the DNS
# forwarder in gateway mode and the NGate TUN helper, and runs connect.exp for
# the connection. It stays PID 1, passes stop signals on and exits with the
# client status. Arguments are passed to ngateconsoleclient.
set -euo pipefail

NGATE_MODE="${NGATE_MODE:-networkmanager}"
CSP_REPO_URL="${CSP_REPO_URL:-https://cryptopro.ru/repo/deb}"
CSP_REPO_SUITE="${CSP_REPO_SUITE:-5.0-unstable}"
CSP_PACKAGES=(lsb-cprocsp-base lsb-cprocsp-rdr-64 lsb-cprocsp-kc1-64 lsb-cprocsp-capilite-64)
CSP_DEB_DIR=/var/cache/apt/cryptopro
APT_AUTH_FILE=/etc/apt/auth.conf.d/cryptopro.conf
APT_SOURCE_FILE=/etc/apt/sources.list.d/cryptopro.list
ROOT_CERTIFICATES_FILE=/run/ngate-client/root-certificates
# Written by the resolvconf stub and read by the DNS forwarder.
DNS_SERVERS_FILE=/run/ngate-client/dns
# CSP tools run through the ELF loader, so host AppArmor profiles attached to
# their paths are not applied.
LOADER=/lib64/ld-linux-x86-64.so.2
CPCONFIG=/opt/cprocsp/sbin/amd64/cpconfig
CERTMGR=/opt/cprocsp/bin/amd64/certmgr
NGATETUN_SOCKET=/tmp/ngatetuncmdint
NGATETUN_CONFIG=/opt/cprongate/service.ini

log() {
  printf 'ngate-client: %s\n' "$*" >&2
}

die() {
  log "error: $*"
  exit 1
}

cleanup_csp_installation() {
  rm -rf "$APT_AUTH_FILE" "$APT_SOURCE_FILE" "$CSP_DEB_DIR"
}

install_csp() {
  local status
  status="$(dpkg-query -W -f='${Status} ${Version}' lsb-cprocsp-capilite-64 2> /dev/null || true)"
  [ "$status" = "install ok installed $CSP_VERSION" ] && return

  [ -n "${CRYPTOPRO_USERNAME:-}" ] && [ -n "${CRYPTOPRO_PASSWORD:-}" ] \
    || die "CRYPTOPRO_USERNAME and CRYPTOPRO_PASSWORD are required to install CryptoPro CSP"
  log "installing CryptoPro CSP $CSP_VERSION"

  trap cleanup_csp_installation EXIT
  (
    umask 077
    printf 'machine %s\nlogin %s\npassword %s\n' \
      "${CSP_REPO_URL#https://}" "$CRYPTOPRO_USERNAME" "$CRYPTOPRO_PASSWORD" > "$APT_AUTH_FILE"
  )
  printf 'deb [arch=amd64 signed-by=/usr/share/keyrings/cryptopro.asc] %s %s main\n' \
    "$CSP_REPO_URL" "$CSP_REPO_SUITE" > "$APT_SOURCE_FILE"
  rm -rf "$CSP_DEB_DIR"
  mkdir -m 0755 "$CSP_DEB_DIR"

  apt-get update
  # Download through apt to keep signature checks, then unpack before
  # configuring so the capilite postinst also calls CSP tools via the loader.
  DEBIAN_FRONTEND=noninteractive apt-get -o "Dir::Cache::archives=$CSP_DEB_DIR" \
    install -y --no-install-recommends --download-only --reinstall "${CSP_PACKAGES[@]/%/=$CSP_VERSION}"
  dpkg --unpack "$CSP_DEB_DIR"/*.deb
  sed -i -E "s#(/opt/cprocsp/bin/amd64/(certmgr|csptest))([[:space:]])#$LOADER \\1\\3#g" \
    /var/lib/dpkg/info/lsb-cprocsp-capilite-64.postinst
  DEBIAN_FRONTEND=noninteractive dpkg --configure --pending

  apt-get clean
  rm -rf /var/lib/apt/lists/*
  cleanup_csp_installation
  trap - EXIT
}

apply_license() {
  if [ -n "${CSP_LICENSE:-}" ]; then
    "$LOADER" "$CPCONFIG" -license -set "$CSP_LICENSE" > /dev/null || die "CryptoPro CSP rejected the license"
  fi
  # Print only the license kind and validity, never the serial number.
  "$LOADER" "$CPCONFIG" -license -view | grep -E '^(license|License type)' >&2 || true
}

# NGATE_ROOT_CERTIFICATES holds a certificate file encoded with base64. It is
# decoded before CSP is downloaded, so a bad value fails early.
decode_root_certificates() {
  rm -f "$ROOT_CERTIFICATES_FILE"
  [ -n "${NGATE_ROOT_CERTIFICATES:-}" ] || return 0
  mkdir -p "${ROOT_CERTIFICATES_FILE%/*}"
  if ! (umask 077 && printf '%s' "$NGATE_ROOT_CERTIFICATES" | base64 -d > "$ROOT_CERTIFICATES_FILE") \
    || [ ! -s "$ROOT_CERTIFICATES_FILE" ]; then
    rm -f "$ROOT_CERTIFICATES_FILE"
    die "NGATE_ROOT_CERTIFICATES is not valid base64 or decodes to nothing"
  fi
}

# stdin is /dev/null, so a certmgr prompt fails instead of hanging.
install_root_certificates() {
  [ -f "$ROOT_CERTIFICATES_FILE" ] || return 0
  log "installing root certificates from NGATE_ROOT_CERTIFICATES"
  if ! "$LOADER" "$CERTMGR" -install -all -store mroot -file "$ROOT_CERTIFICATES_FILE" < /dev/null >&2; then
    rm -f "$ROOT_CERTIFICATES_FILE"
    die "certmgr failed to install the root certificates from NGATE_ROOT_CERTIFICATES"
  fi
  rm -f "$ROOT_CERTIFICATES_FILE"
}

# Lets other hosts route traffic into the tunnel through this container.
# Forwarding is limited to tun0, so addresses the gateway does not route are
# rejected instead of looping back to the host that sent them.
enable_nat() {
  local ipt

  if [ "$(cat /proc/sys/net/ipv4/ip_forward)" != 1 ]; then
    echo 1 2> /dev/null > /proc/sys/net/ipv4/ip_forward \
      || die "cannot enable IP forwarding, run the container with --sysctl net.ipv4.ip_forward=1"
  fi
  # The kernel may support only one of the iptables backends.
  for ipt in iptables iptables-legacy; do
    "$ipt" -t nat -S > /dev/null 2>&1 || continue
    add_rule "$ipt" nat POSTROUTING -o tun0 -j MASQUERADE
    add_rule "$ipt" mangle FORWARD -o tun0 -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
    add_rule "$ipt" filter FORWARD -o tun0 -j ACCEPT
    add_rule "$ipt" filter FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    add_rule "$ipt" filter FORWARD -j REJECT
    log "forwarding traffic into tun0 with $ipt"
    return
  done
  die "neither iptables nor iptables-legacy can manage the nat table"
}

# Appends an iptables rule unless it is already present.
add_rule() {
  local ipt="$1" table="$2" chain="$3"
  shift 3
  "$ipt" -t "$table" -C "$chain" "$@" 2> /dev/null || "$ipt" -t "$table" -A "$chain" "$@"
}

# Answers DNS on port 53 of the container through the servers of the current
# NGate session. It starts without servers; the resolvconf stub replaces the
# file on every session change, and dnsmasq rereads it. dnsmasq stays root
# because the stub creates the file with mode 0600. Queries are not logged.
start_dns_forwarder() {
  mkdir -p "${DNS_SERVERS_FILE%/*}"
  : > "$DNS_SERVERS_FILE"
  dnsmasq --resolv-file="$DNS_SERVERS_FILE" --no-hosts --bind-dynamic --except-interface=tun0 \
    --user=root --log-facility=/proc/1/fd/2 \
    || die "dnsmasq failed to start the DNS forwarder"
  log "DNS forwarder listening on port 53"
}

# networkmanager: the container uses the host network, and ngatetun configures
# routes and DNS through the host NetworkManager.
# gateway: the container has its own network, ngatetun configures routes with
# ip and passes DNS to resolvconf, and other hosts reach the tunnel through NAT
# and resolve its names through the DNS forwarder.
configure_mode() {
  case "$NGATE_MODE" in
    networkmanager)
      [ -S /run/dbus/system_bus_socket ] \
        || die "host D-Bus socket is missing, mount /run/dbus/system_bus_socket into the container"
      nmcli --wait 5 --terse --fields RUNNING general > /dev/null \
        || die "cannot reach the host NetworkManager through the system D-Bus socket"
      rm -f "$NGATETUN_CONFIG"
      ;;
    gateway)
      printf 'ignoreNetworkManager=1\n' > "$NGATETUN_CONFIG"
      enable_nat
      start_dns_forwarder
      ;;
    *)
      die "NGATE_MODE must be networkmanager or gateway"
      ;;
  esac
}

start_ngatetun() {
  local i
  # Files left by the previous run of a restarted container block the start.
  rm -f /var/run/ngatetun.pid "$NGATETUN_SOCKET"
  /opt/cprongate/ngatetun -v &
  for ((i = 0; i < 50; i++)); do
    [ -S "$NGATETUN_SOCKET" ] && return
    sleep 0.2
  done
  die "ngatetun did not create $NGATETUN_SOCKET"
}

[ -c /dev/net/tun ] || die "/dev/net/tun is missing, run the container with --device /dev/net/tun"
configure_mode
for name in NGATE_URL NGATE_USERNAME NGATE_PASSWORD; do
  [ -n "${!name:-}" ] || die "$name is required"
done

decode_root_certificates
install_csp
apply_license
install_root_certificates
start_ngatetun

unset CRYPTOPRO_USERNAME CRYPTOPRO_PASSWORD CSP_LICENSE NGATE_ROOT_CERTIFICATES
expect -f /usr/local/lib/ngate-client/connect.exp -- "$@" &
client_pid=$!

# The entrypoint stays PID 1 with real signal handlers: RouterOS kills a
# container at once when its first process catches no stop signal.
# connect.exp passes TERM on to the client, and an interrupted wait is
# repeated until connect.exp has exited.
trap 'kill -TERM "$client_pid" 2> /dev/null || true' TERM INT
while :; do
  status=0
  wait "$client_pid" || status=$?
  kill -0 "$client_pid" 2> /dev/null || break
done
exit "$status"
