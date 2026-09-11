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

## [0.1.0] - 2026-09-11

### Added

- Orchestrates `rustfs-bucket-user` and `onepassword-item` to provision a kopiur backup bucket/user and
  write the resulting credentials (plus a generated `KOPIA_PASSWORD`) into a single `kopiur-backup#<env>`
  1Password item.
- Owns configuration of both the `rustfs` and `onepassword` providers, since its two child modules are
  provider-config-free (per Terraform's guidance on providers within modules).

### Changed

- `var.name` is now the shared *base* name (defaulting to `"kopiur-backup"`) instead of the full
  bucket/user/policy name -- the module derives `<env>-<name>` for `rustfs-bucket-user` and `<name>#<env>`
  for the 1Password item title itself, so the `kopiur-backup` string lives in exactly one place (this
  variable's default) instead of being duplicated in the item title (previously hardcoded here) and in
  every caller's own `<env>-kopiur-backup` computation.
