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

### Changed

### Removed

### Fixed

## [0.1.0] - 2026-10-08

### Added

- Initial module: a dedicated API-only host (`tag_address_family = no-ip`, `tag_agent = special-agents`) in an existing folder, one special-agent rule per RustFS monitoring identity for the ruleset `special_agents:rustfs_quota` (endpoint, access key, Password Store reference as the secret, bucket list; gated by `rules_enabled`, default `false`), and an activation with `force_foreign_changes = false` that re-runs when the host or a rule changes. Uses the community provider `registry.terraform.io/blackmesaltd/checkmk` (v0.0.5, pinned exactly). A rule for the polling interval of the host (`check_interval_minutes`, default 15; Checkmk's default of one minute would mean a request per bucket every minute). Offline `tofu test` (mocked provider). ([#49](https://github.com/isejalabs/terraform-modules/pull/49))
