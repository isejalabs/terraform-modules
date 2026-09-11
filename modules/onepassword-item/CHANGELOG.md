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

- `onepassword_item` resource, generic over `var.sections`/`var.fields`: any module generating credentials can reuse this instead of hand-rolling its own `onepassword_item` resource.
- Items are tagged `iac-managed` by default (`var.tags`) and accept a plain-text `var.note`, so it's clear in the 1Password UI that hand-editing fields will be reverted on the next `apply`.

### Changed

### Removed

- `var.onepassword` (provider credentials). This module no longer configures the `onepassword` provider
  itself -- per Terraform's guidance on providers within modules, only the calling root should do that.

### Fixed
