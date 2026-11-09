# Repository Layout

```text
.
├── .github/workflows/
├── docker/
│   ├── hugo-autoprefixer/
│   │   ├── Dockerfile
│   │   └── docker-bake.json
│   ├── lvm/
│   │   ├── Dockerfile
│   │   └── docker-bake.json
│   ├── ngate-client/
│   │   ├── Dockerfile
│   │   ├── connect.exp
│   │   ├── cryptopro-package-signing-key.asc
│   │   ├── docker-bake.json
│   │   └── entrypoint.sh
│   ├── py-astral-stack/
│   │   ├── Dockerfile
│   │   └── docker-bake.json
│   └── updatecli-python-nodejs/
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
tags. An image directory may also hold files copied into the image, such as
entrypoint scripts or signing keys.

## `.github/workflows/`

GitHub Actions workflows discover changed image directories and delegate
verification and publication to released Dagger scenarios.

## `renovate.json`

Renovate configuration for operational dependency pins committed in this
repository.

## `Makefile`

Repository-level entry points for local and CI changed-component discovery,
image verification, publication, and dry-run publication.
