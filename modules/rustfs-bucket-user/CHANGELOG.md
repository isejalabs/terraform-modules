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

Initial module implementation -- not tagged/released yet.

### Added

- `rustfs_bucket`, `rustfs_policy` (scoped to only that bucket), and `rustfs_user` (dedicated, least-privilege) resources, so each consumer of RustFS storage gets its own bucket and credentials instead of sharing admin credentials ([#13](https://github.com/isejalabs/terraform-modules/pull/13)).
- `var.quota` (default 10 GiB) via `rustfs_quota`.
- `var.versioning_enabled` -- accepted but currently a no-op; `rustfs_bucket_versioning` isn't in any published `weinmann-emt/rustfs` provider release yet (see [#14](https://github.com/isejalabs/terraform-modules/issues/14)).

### Changed

### Removed

### Fixed
