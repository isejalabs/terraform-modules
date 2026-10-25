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

- `ldap.user_attributes` (username, e-mail, first name, last name) and explicit user attribute mappers per realm, including read-only creation/modify timestamps. ([#N](https://github.com/isejalabs/terraform-modules/issues/72))

### Changed

- The federation deletes Keycloak's default mappers (`delete_default_mappers`), which only takes effect when the federation is created: an existing federation must be replaced once (`-replace`) to adopt this. ([#N](https://github.com/isejalabs/terraform-modules/issues/72))

### Removed

- The default Kerberos principal attribute mapper is no longer created; Kerberos is set up separately (isejalabs/homelab#1827).

### Fixed

- The first name is read from `givenName`, not `cn` (the full name in UCS), which showed users as "Sebastian Klamar Klamar". ([#N](https://github.com/isejalabs/terraform-modules/issues/72))

## [0.1.0] - 2026-10-25

### Added

- Initial module: one Keycloak realm per entry of `realms` (password policy, brute-force detection, security headers, WebAuthn policy), each with a read-only, importing LDAP federation to UCS over LDAPS with several connection URLs for failover and a per-realm user filter, a group mapper, and a `groups` client scope with a group-membership mapper. The provider login and the LDAP bind credential are read from 1Password. Uses the `keycloak/keycloak` provider (`~> 5.10`). The realm settings, security headers, brute-force detection, WebAuthn policy, group claim and the LDAP/group-mapper tuning are variables with defaults. An offline `tofu test` (mocked providers) covers the per-realm resources, the federation settings, defaults/overrides and the input validation. ([#66](https://github.com/isejalabs/terraform-modules/issues/66))
