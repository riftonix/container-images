## ADDED Requirements

### Requirement: LVM image target is described

The repository SHALL describe the `lvm` image with a local Docker Bake target containing its context, Dockerfile, version inputs, publish tag, OCI labels, and validated platforms.

#### Scenario: LVM Bake target is resolved

- **WHEN** `docker/lvm/docker-bake.json` is resolved with default variables
- **THEN** it defines one `lvm` target whose image reference uses the default registry and repository prefix and whose tag is rendered from the exact Wolfi LVM2 package version

### Requirement: LVM image dependency pins are managed

The LVM image Bake manifest SHALL define `WOLFI_BASE_DIGEST` and `LVM_PACKAGE_VERSION` variables, and each managed variable SHALL expose Renovate metadata through its `description` field.

#### Scenario: A supported LVM dependency update is available

- **WHEN** Renovate detects a newer supported base digest or exact Wolfi package version
- **THEN** it proposes an update to the matching variable in `docker/lvm/docker-bake.json`

#### Scenario: Non-version inputs change

- **WHEN** the Wolfi base digest or default command changes without changing `LVM_PACKAGE_VERSION`
- **THEN** the resolved LVM image tag remains unchanged

### Requirement: LVM image verification covers runtime behavior

Verification for the LVM image SHALL validate both the Bake build and the image-specific command behavior required by the LVM image specification.

#### Scenario: Verify LVM image component

- **WHEN** the LVM image component is verified before publication
- **THEN** verification confirms the expected LVM commands and versions are present and the default command remains running

#### Scenario: Validate privileged block-device behavior

- **WHEN** a suitable privileged test environment is available
- **THEN** verification exercises physical volume and volume group creation on a disposable block device without modifying host production storage
