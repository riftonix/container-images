# Container Image Bake Pipeline Delta Specification

## MODIFIED Requirements

### Requirement: LVM image dependency pins are managed

The LVM image SHALL pin its Wolfi base image by tag and digest in the base image reference of `docker/lvm/Dockerfile`. The LVM image Bake manifest SHALL define the exact Wolfi `lvm2` package version, including its apk revision, in the `LVM_PACKAGE_VERSION` variable, and that variable SHALL expose Renovate metadata through its `description` field. The LVM image Bake manifest SHALL NOT define a variable for the base image digest.

#### Scenario: A supported LVM dependency update is available

- **WHEN** Wolfi defines a newer `lvm2` package version or revision than `LVM_PACKAGE_VERSION`
- **THEN** Renovate proposes an update to `LVM_PACKAGE_VERSION` in `docker/lvm/docker-bake.json` that includes the apk revision

#### Scenario: A newer base image digest is available

- **WHEN** the pinned Wolfi base image tag resolves to a newer digest
- **THEN** Renovate proposes an update to the digest in the base image reference of `docker/lvm/Dockerfile`

#### Scenario: Non-version inputs change

- **WHEN** the Wolfi base digest or default command changes without changing `LVM_PACKAGE_VERSION`
- **THEN** the resolved LVM image tag remains unchanged
