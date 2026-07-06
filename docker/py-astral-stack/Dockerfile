ARG UV_VERSION
ARG PYTHON_VERSION

FROM astral/uv:${UV_VERSION}-python${PYTHON_VERSION}-alpine

ARG RUFF_VERSION
ARG TY_VERSION

ENV UV_TOOL_BIN_DIR=/usr/local/bin

RUN uv tool install --no-cache "ruff==${RUFF_VERSION}" \
 && uv tool install --no-cache "ty==${TY_VERSION}"
