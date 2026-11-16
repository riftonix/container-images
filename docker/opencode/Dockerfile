ARG OPENCODE_VERSION

FROM ghcr.io/anomalyco/opencode:${OPENCODE_VERSION}

ARG OPENCODE_VERSION

USER root
RUN apk upgrade --no-cache \
 && apk add --no-cache \
      ca-certificates \
      bash \
      coreutils \
      findutils \
      grep \
      sed \
      gawk \
      git \
      openssh-client-default \
      curl \
      ripgrep \
      jq \
      tar \
      gzip \
      unzip \
      xz \
      make \
      diffutils \
      patch \
      python3 \
      uv \
      ruff \
      procps-ng \
      tini \
      nodejs \
      npm \
      kubectl \
 && test "$(opencode --version)" = "opencode v${OPENCODE_VERSION}" \
 && addgroup -g 65532 agent \
 && adduser -D -u 65532 -G agent -s /bin/bash agent \
 && mkdir -p /workspace /tools/bin /home/agent/.config /home/agent/.cache /home/agent/.local/share /home/agent/.local/state \
 && chown -R agent:agent /workspace /tools /home/agent

ENV HOME=/home/agent \
    XDG_CONFIG_HOME=/home/agent/.config \
    XDG_CACHE_HOME=/home/agent/.cache \
    XDG_DATA_HOME=/home/agent/.local/share \
    XDG_STATE_HOME=/home/agent/.local/state \
    UV_TOOL_BIN_DIR=/tools/bin \
    NPM_CONFIG_PREFIX=/tools \
    PATH=/tools/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

COPY smoke-test.sh /usr/local/share/opencode-image/smoke-test.sh
USER 65532:65532
WORKDIR /workspace
RUN sh /usr/local/share/opencode-image/smoke-test.sh

ENTRYPOINT ["/sbin/tini", "-g", "--", "opencode"]
