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

- Optional VLAN ID support for nodes.

### Changed

- Pinned `cpu.type` to `x86-64-v2-AES`.
- Bumped the `cilium/cilium` chart version (routine, via Renovate; latest is `1.18.1`).

### Fixed

- Removed the dynamic part of the image factory schematic used by `proxmox_virtual_environment_download_file` (workaround for a `schematic_id` issue).

## [0.0.2] - 2024-11-03

### Changed

- Made `mac_address` and other node parameters optional.

## [0.0.1] - 2024-11-02

### Added

- Initial module, ported from Vegard Hagen's ([@vehagn](https://github.com/vehagn)) Talos-on-Proxmox implementation: provisions Proxmox VMs and bootstraps a Talos Linux Kubernetes cluster on them (machine secrets/configuration, image factory schematic, cluster health/kubeconfig).
