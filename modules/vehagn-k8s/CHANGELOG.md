# Changelog

All _notable_ changes to this module will be documented in this file, following the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

This module has moved to its own repo -- see [`isejalabs/terraform-proxmox-talos`](https://github.com/isejalabs/terraform-proxmox-talos) and its own [CHANGELOG.md](https://github.com/isejalabs/terraform-proxmox-talos/blob/main/CHANGELOG.md) for anything past the entry below. Nothing here is expected to change going forward.

## [Unreleased] - final state before the move

These changes shipped before the module was removed from this repo but were never tagged.

### Added

- Configurable CPU (previously hardcoded).

### Changed

- **Breaking:** the dedicated CSI role & user now use an environment-specific prefix.
- Bumped the `cilium/cilium` chart version (routine, via Renovate).

### Fixed

- The path to Cilium values is now correctly treated as a file path.

### Removed

- Module code removed from this repo as of 2025-07-24; moved to its own repo, [`isejalabs/terraform-proxmox-talos`](https://github.com/isejalabs/terraform-proxmox-talos) (`cfd8b5d9`). What remains here is only a pointer.

## [0.1.0] - 2024-12-04

### Added

- Configurable Cilium values.

## [0.0.3] - 2024-11-23

### Added

- Support for Proxmox CSI volumes and sealed secrets.
- Allow a single control-plane node (previously required a minimum of 3).

### Changed

- Bumped `bpg/proxmox`, `siderolabs/talos`, and `hashicorp/kubernetes` provider requirements (routine, via Renovate).

## [0.0.2] - 2024-11-17

### Changed

- **Breaking:** node and other environment-specific configuration is now driven by variables instead of being hardcoded.

## [0.0.1] - 2024-11-17

### Added

- Initial module: provisions Proxmox VMs and bootstraps a Talos Linux Kubernetes cluster on them; working `terragrunt apply` and output (without the bootstrap module).

### Fixed

- Removed the dynamic part of the image factory schematic used by `proxmox_virtual_environment_download_file`.
