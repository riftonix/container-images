FROM docker.io/library/ubuntu:26.04@sha256:6a06111c3b0a8600feadb270aec771dc239bf407b25625f93f44ab00e11f4d3c

ARG CSP_VERSION
ARG NGATE_VERSION
ARG NGATE_TUN_SHA256
ARG NGATE_CONSOLE_SHA256
ARG NGATE_REPO_URL=https://ng-client.cryptopro.ru/repository/debian/amd64_snapshot

# CryptoPro CSP requires an authenticated repository, so the entrypoint
# installs this pinned version on the first container start.
ENV CSP_VERSION="${CSP_VERSION}"

# nmcli uses the host NetworkManager through its mounted system D-Bus socket.
# Prevent package scripts from starting services during build and runtime.
RUN printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d \
 && chmod 0755 /usr/sbin/policy-rc.d \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      expect \
      iproute2 \
      libdbus-1-3 \
      libglib2.0-0t64 \
      lsb-base \
      network-manager \
      tini \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# The NGate packages depend on CSP packages that are not available at build
# time. Their maintainer scripts only register and start the ngatetun service,
# which the entrypoint does itself, so only /opt/cprongate is extracted.
RUN set -eu; \
    tun="cprongate-tun_${NGATE_VERSION}_amd64.deb"; \
    console="cprongate-console_${NGATE_VERSION}_amd64.deb"; \
    workdir="$(mktemp -d)"; \
    cd "${workdir}"; \
    curl -fsSLO "${NGATE_REPO_URL}/${tun}"; \
    curl -fsSLO "${NGATE_REPO_URL}/${console}"; \
    printf '%s  %s\n' "${NGATE_TUN_SHA256}" "${tun}" "${NGATE_CONSOLE_SHA256}" "${console}" \
      | sha256sum --check --strict -; \
    dpkg-deb -x "${tun}" root; \
    dpkg-deb -x "${console}" root; \
    cp -a root/opt/cprongate /opt/cprongate; \
    cd /; \
    rm -rf "${workdir}"; \
    dependencies="$(ldd /opt/cprongate/ngatetun /opt/cprongate/ngateconsoleclient)"; \
    ! printf '%s\n' "${dependencies}" | grep 'not found'

COPY cryptopro-package-signing-key.asc /usr/share/keyrings/cryptopro.asc
COPY entrypoint.sh /usr/local/bin/ngate-client-entrypoint
COPY connect.exp /usr/local/lib/ngate-client/connect.exp

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/ngate-client-entrypoint"]
