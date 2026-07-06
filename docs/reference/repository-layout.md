# Repository Layout

```text
.
├── .github/workflows/
├── docker/
│   ├── hugo-autoprefixer/
│   │   ├── Dockerfile
│   │   └── docker-bake.json
│   └── py-astral-stack/
│       ├── Dockerfile
│       └── docker-bake.json
├── docs/
│   ├── tutorials/
│   ├── how-to/
│   ├── reference/
│   └── explanation/
├── renovate.json
├── Makefile
├── README.md
└── LICENSE
```

## `docker/`

Each child directory is an independently versioned OCI image. Its
`docker-bake.json` file defines build arguments, labels, platforms, and publish
tags.

## `.github/workflows/`

GitHub Actions workflows discover changed image directories and delegate
verification and publication to released Dagger scenarios.

## `renovate.json`

Renovate configuration for operational dependency pins committed in this
repository.

## `Makefile`

Repository-level entry points for local and CI changed-component discovery,
image verification, publication, and dry-run publication.
