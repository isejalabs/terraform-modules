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

### Changed

- Bumped `bpg/proxmox` provider requirement to `0.83.1` and `siderolabs/talos` to `0.8.1` (from `0.66.3`/`0.6.1` at [0.0.3](#003---2024-11-02)) via routine Renovate updates.

## [0.0.3] - 2024-11-02

### Changed

- Bumped `siderolabs/talos` provider requirement to `0.6.1`.

## [0.0.2] - 2024-10-31

### Added

- Initial module: provisions Proxmox VMs for Talos Linux Kubernetes nodes (`proxmox_virtual_environment_vm`), one per entry in `var.nodes`.

`0.0.1` points to the same commit as `0.0.2` -- no separate content.
