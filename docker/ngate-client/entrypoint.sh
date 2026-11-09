#!/bin/bash
# Installs CryptoPro CSP on the first start, applies the CSP license and
# trusted root certificates, starts the NGate TUN helper, and hands the
# connection over to connect.exp. Arguments are passed to ngateconsoleclient.
set -euo pipefail

CSP_REPO_URL="${CSP_REPO_URL:-https://cryptopro.ru/repo/deb}"
CSP_REPO_SUITE="${CSP_REPO_SUITE:-5.0-unstable}"
CSP_PACKAGES=(lsb-cprocsp-base lsb-cprocsp-rdr-64 lsb-cprocsp-kc1-64 lsb-cprocsp-capilite-64)
CSP_DEB_DIR=/var/cache/apt/cryptopro
APT_AUTH_FILE=/etc/apt/auth.conf.d/cryptopro.conf
APT_SOURCE_FILE=/etc/apt/sources.list.d/cryptopro.list
CA_DIR=/etc/ngate-client/ca.d
# CSP tools run through the ELF loader, so host AppArmor profiles attached to
# their paths are not applied.
LOADER=/lib64/ld-linux-x86-64.so.2
CPCONFIG=/opt/cprocsp/sbin/amd64/cpconfig
CERTMGR=/opt/cprocsp/bin/amd64/certmgr
NGATETUN_SOCKET=/tmp/ngatetuncmdint

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

install_root_certificates() {
  local cert
  for cert in "$CA_DIR"/*; do
    [ -f "$cert" ] || continue
    log "installing root certificate ${cert##*/}"
    "$LOADER" "$CERTMGR" -install -store mroot -file "$cert" < /dev/null > /dev/null \
      || die "failed to install root certificate $cert"
  done
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
[ -S /run/dbus/system_bus_socket ] \
  || die "host D-Bus socket is missing, mount /run/dbus/system_bus_socket into the container"
for name in NGATE_URL NGATE_USERNAME NGATE_PASSWORD; do
  [ -n "${!name:-}" ] || die "$name is required"
done

install_csp
apply_license
install_root_certificates
start_ngatetun

unset CRYPTOPRO_USERNAME CRYPTOPRO_PASSWORD CSP_LICENSE
exec expect -f /usr/local/lib/ngate-client/connect.exp -- "$@"
