# Changelog

All _notable_ changes to this module will be documented in this file, following the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format. It won't include each and every change and commit (e.g. ci or documentation changes), but only the notable changes, in a human-readable format that commit messages sometimes do not provide.

This module tries to adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Hence, a change to the version number X.Y.Z will indicate a

- **X+1: breaking changes** in **major** version numbers,
- **Y+1: feature updates** (and possbily bug fixes) in **minor** version numbers, and
- **Z+1: bug fixes** only in **patch** version numbers.

## [Unreleased]

### Added

- Initial module: a confidential service-account client in the `master` realm (client-credentials grant only) with `create-realm` and, for `existing_realms`, `realm-admin` of the realm's management client; its generated secret is written to a 1Password login item and can be rotated with `secret_rotation`. ([#82](https://github.com/isejalabs/terraform-modules/issues/82))

### Changed

### Removed

### Fixed
