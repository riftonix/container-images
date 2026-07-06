# Container Images Documentation

This documentation separates task-oriented guides, reference material, and
design explanations so each page has one clear purpose.

## Recommended Reading Path

1. Read [Repository layout](reference/repository-layout.md) to understand where
   image sources and Bake manifests live.
2. Read [Verify and dry-run publish an image](how-to/verify-and-dry-run-publish.md)
   before publishing image changes.
3. Read the per-image reference pages
   ([hugo-autoprefixer](reference/hugo-autoprefixer.md),
   [py-astral-stack](reference/py-astral-stack.md)) for build arguments,
   publish tags, and Renovate metadata.
4. Read [Dependency updates](reference/dependency-updates.md) when adding or
   auditing operational version pins.
5. Read [Dependency update design](explanation/dependency-updates.md) when you
   need the reasoning behind Renovate metadata and classification labels.

## Documentation Structure

- [Tutorials](tutorials/README.md) teach by walking through complete examples.
- [How-to guides](how-to/README.md) solve concrete operational tasks.
- [Reference](reference/README.md) lists stable repository facts and contracts.
- [Explanation](explanation/README.md) describes design choices and tradeoffs.
