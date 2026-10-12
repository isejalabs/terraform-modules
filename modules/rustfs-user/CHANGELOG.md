# Changelog

All _notable_ changes to this module will be documented in this file, following the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format. It won't include each and every change and commit (e.g. ci or documentation changes), but only the notable changes, in a human-readable format that commit messages sometimes do not provide.

This module tries to adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Hence, a change to the version number X.Y.Z will indicate a

- **X+1: breaking changes** in **major** version numbers,
- **Y+1: feature updates** (and possbily bug fixes) in **minor** version numbers, and
- **Z+1: bug fixes** only in **patch** version numbers.

<!--
> [!NOTE]
> [!TIP]
> [!IMPORTANT]
> [!WARNING]
> [!CAUTION]
-->

<!---
## [Unreleased Template]
### Changed

### Added

### Removed

### Fixed

## [X.Y.Z] - YYYY-MM-DD
-->

## [Unreleased]

### Added

- Initial module: a `rustfs_policy`, a `random_password` and a `rustfs_user` attached to that policy, extracted from `rustfs-bucket-user` and `rustfs-bucket-reader`, which created the same core twice. Inputs `name`, `policy_name`, `actions`, `bucket_names` and `include_objects` (also grant the object ARNs `/*`); outputs `access_key`, sensitive `secret_key` and `policy_name`. ([#37](https://github.com/isejalabs/terraform-modules/issues/37))

### Changed

### Removed

### Fixed
