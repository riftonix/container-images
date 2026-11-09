# Container Images Documentation

This documentation separates task-oriented guides, reference material, and
design explanations so each page has one clear purpose.

## Recommended Reading Path

1. Read [Repository layout](reference/repository-layout.md) to understand where
   image sources and Bake manifests live.
2. Read [Verify and dry-run publish an image](how-to/verify-and-dry-run-publish.md)
   before publishing image changes.
3. Review the [Images](#images) catalog and follow the reference link for the
   image you need.
4. Read [Dependency updates](reference/dependency-updates.md) when adding or
   auditing operational version pins.
5. Read [Dependency update design](explanation/dependency-updates.md) when you
   need the reasoning behind Renovate metadata and classification labels.

## Images

### [hugo-autoprefixer](reference/hugo-autoprefixer.md)

Bundles Hugo with the `autoprefixer` PostCSS plugin installed globally through
npm. Use it to build Hugo sites that require CSS vendor prefix generation.

### [lvm](reference/lvm.md)

Provides versioned LVM2 tools for privileged block-device administration. It
supports Kubernetes storage initialization workloads and remains running with
`sleep infinity` unless its command is overridden.

### [ngate-client](reference/ngate-client.md)

Connects a Linux host to a CryptoPro NGate VPN gateway with the vendor console
client. The NGate client is part of the image, CryptoPro CSP is installed on
the first container start, and credentials and the CSP license are passed
at runtime.

### [py-astral-stack](reference/py-astral-stack.md)

Bundles Python with the Astral toolchain: `uv`, `ruff`, and `ty`. Use it for
Python dependency management, linting, formatting, and type checking without
installing those tools at runtime.

### [updatecli-python-nodejs](reference/updatecli-python-nodejs.md)

Bundles Updatecli with Python, PyYAML, Node.js, npm, and git. Use it to run
Updatecli pipelines whose shell resources call Python scripts, `npx`-based
generators, or git.

## Documentation Structure

- [Tutorials](tutorials/README.md) teach by walking through complete examples.
- [How-to guides](how-to/README.md) solve concrete operational tasks.
- [Reference](reference/README.md) lists stable repository facts and contracts.
- [Explanation](explanation/README.md) describes design choices and tradeoffs.
