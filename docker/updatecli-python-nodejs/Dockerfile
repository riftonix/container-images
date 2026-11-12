ARG UPDATECLI_VERSION

FROM ghcr.io/updatecli/updatecli:v${UPDATECLI_VERSION} AS updatecli

FROM docker.io/nikolaik/python-nodejs:python3.14-nodejs26@sha256:0ff4353fdbdae8b86a5ebe044b422064b12073f9a624f646ac3a01eab9457359

ARG PYTHON_VERSION
ARG NODE_VERSION
ARG PYYAML_VERSION

COPY --from=updatecli /usr/local/bin/updatecli /usr/local/bin/updatecli

RUN pip install --no-cache-dir --root-user-action=ignore "PyYAML==${PYYAML_VERSION}" \
 && test "$(python -c 'import sys; print("%d.%d" % sys.version_info[:2])')" = "${PYTHON_VERSION}" \
 && test "$(node -p 'process.versions.node.split(".")[0]')" = "${NODE_VERSION}" \
 && python -c 'import yaml' \
 && updatecli version \
 && git --version \
 && npx --version

USER pn
WORKDIR /home/pn
