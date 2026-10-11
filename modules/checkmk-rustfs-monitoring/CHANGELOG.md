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

- **Breaking:** one API-only host per identity instead of one shared host: the variable `host_name` is replaced by `host_name_format` (a pattern with `%s` for the identity key, for example `rustfs-%s.fiona.example.com`), the polling-interval rule is created per host, and the output `host_name` is replaced by the map `host_names`. Migration: the former shared host is destroyed and one host per identity is created. ([#52](https://github.com/isejalabs/terraform-modules/issues/52))

### Removed

### Fixed

- Only one identity was polled: Checkmk runs just the first matching rule of the special-agent ruleset per host, so with several identities on one host all but one stayed unpolled. ([#52](https://github.com/isejalabs/terraform-modules/issues/52))

## [0.1.0] - 2026-10-08

### Added

- Initial module: a dedicated API-only host (`tag_address_family = no-ip`, `tag_agent = special-agents`) in an existing folder, one special-agent rule per RustFS monitoring identity for the ruleset `special_agents:rustfs_quota` (endpoint, access key, Password Store reference as the secret, bucket list; gated by `rules_enabled`, default `false`), and an activation with `force_foreign_changes = false` that re-runs when the host or a rule changes. Uses the community provider `registry.terraform.io/blackmesaltd/checkmk` (v0.0.5, pinned exactly). A rule for the polling interval of the host (`check_interval_minutes`, default 15; Checkmk's default of one minute would mean a request per bucket every minute). Offline `tofu test` (mocked provider). ([#49](https://github.com/isejalabs/terraform-modules/pull/49))
