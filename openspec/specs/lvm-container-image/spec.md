## Purpose

Define a reproducible, minimal OCI image that provides LVM2 tools for privileged block-device administration without installing packages at container startup.

## Requirements

### Requirement: LVM image identity

The repository SHALL provide the image component as `lvm` and SHALL publish it to `${REGISTRY}/${REPOSITORY_PREFIX}/lvm`.

#### Scenario: Default publication destination

- **WHEN** the image is published with the default registry and repository prefix
- **THEN** its repository is `ghcr.io/riftonix/container-images/lvm`

### Requirement: Package-derived image version

The image tag SHALL equal the exact installed Wolfi `lvm2` package version, including its apk revision, and SHALL NOT include the Wolfi base version, base digest, or default command.

#### Scenario: Image for an LVM2 package version

- **WHEN** an image containing Wolfi package `lvm2=2.03.42-r1` is published
- **THEN** the image tag is `2.03.42-r1`

#### Scenario: Build inputs change

- **WHEN** the Wolfi base digest or default command changes without changing `LVM_PACKAGE_VERSION`
- **THEN** the resolved image tag remains equal to `LVM_PACKAGE_VERSION`

### Requirement: LVM runtime tools

The image SHALL contain `lvm`, `pvcreate`, `vgcreate`, and `vgs`, their required runtime libraries, and usable default LVM configuration.

#### Scenario: Inspect installed LVM version

- **WHEN** a caller runs the LVM version command in the image
- **THEN** the command succeeds and reports the version represented by the image tag

#### Scenario: Create a physical volume and volume group

- **WHEN** the image runs with the required privileges and access to a disposable block device
- **THEN** `pvcreate` and `vgcreate` succeed and `vgs` reports the created volume group

### Requirement: Persistent default command

The image SHALL run `sleep infinity` when the caller supplies no command.

#### Scenario: Start without command override

- **WHEN** a container is started from the image without a command override
- **THEN** the container remains running until it is stopped

### Requirement: Minimal compatible base

The image SHALL use Wolfi when its LVM2 package passes command and privileged block-device validation. If Wolfi does not pass that validation, the implementation SHALL use Alpine, and SHALL use a minimal Ubuntu base only if both apk-based distributions are incompatible.

#### Scenario: Wolfi passes validation

- **WHEN** the Wolfi image builds and completes the required LVM functional checks
- **THEN** the published image uses Wolfi as its base

#### Scenario: Wolfi fails validation

- **WHEN** a reproducible Wolfi incompatibility prevents a required LVM functional check
- **THEN** the implementation records the failure and validates the same image behavior using Alpine before considering Ubuntu

### Requirement: Supported architectures

The image SHALL be published for every repository-standard platform on which the selected base and required LVM2 packages pass functional validation.

#### Scenario: Both standard platforms pass validation

- **WHEN** LVM functionality is validated for `linux/amd64` and `linux/arm64`
- **THEN** the Bake target declares both platforms

#### Scenario: A standard platform cannot provide the required behavior

- **WHEN** a selected base or package cannot pass the required LVM validation on a standard platform
- **THEN** publication excludes that platform and the limitation is documented
