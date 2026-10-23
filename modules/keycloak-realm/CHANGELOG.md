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

- Initial module: one Keycloak realm per entry of `realms` (password policy, brute-force detection, security headers, WebAuthn policy), each with a read-only, importing LDAP federation to UCS over LDAPS with several connection URLs for failover and a per-realm user filter, a group mapper, and a `groups` client scope with a group-membership mapper. The provider login and the LDAP bind credential are read from 1Password. Uses the `keycloak/keycloak` provider (`~> 5.10`). An offline `tofu test` (mocked providers) covers the per-realm resources, the federation settings and the input validation. ([#66](https://github.com/isejalabs/terraform-modules/issues/66))

### Changed

### Removed

### Fixed
